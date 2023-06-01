import cv2
import numpy as np
from scipy import spatial
from sklearn.cluster import KMeans
import tkinter as tk
from tkinter import filedialog, messagebox
from scipy.spatial import cKDTree


def k_means_clustering(image, n_clusters=5):
    reshaped_image = image.reshape((-1, 3))
    kmeans = KMeans(n_clusters=n_clusters, n_init=10)
    kmeans.fit(reshaped_image)
    return kmeans.cluster_centers_



def determine_color_ranges(palette):
    color_ranges = []
    for color in palette:
        lower_bound = np.clip(color - 20, 0, 255)
        upper_bound = np.clip(color + 20, 0, 255)
        color_ranges.append((lower_bound, upper_bound))
    return color_ranges


def calculate_color_ratios(image, color_ranges):
    color_ratios = []
    for lower_bound, upper_bound in color_ranges:
        mask = cv2.inRange(image, lower_bound, upper_bound)
        ratio = np.sum(mask > 0) / np.prod(mask.shape)
        color_ratios.append(ratio)
    return color_ratios


def apply_brightness_transfer(image, target_palette, reference_palette, target_ratios, reference_ratios):
    image = image.astype(np.float32)
    tree = cKDTree(target_palette)

    for i in range(image.shape[0]):
        for j in range(image.shape[1]):
            distance, index = tree.query(image[i, j, :])
            brightness_ratio = reference_ratios[index] / target_ratios[index]
            image[i, j, 0] *= brightness_ratio

    return np.clip(image, 0, 255).astype(np.uint8)


def apply_color_transfer(image, target_palette, reference_palette):
    target_mean, target_std = np.mean(target_palette, axis=0), np.std(target_palette, axis=0)
    reference_mean, reference_std = np.mean(reference_palette, axis=0), np.std(reference_palette, axis=0)

    # Create a k-d tree for the reference palette
    tree = spatial.KDTree(reference_palette[:, 1:])

    result_image = image.copy().astype(np.float32)
    h, w = image.shape[:2]
    for i in range(h):
        for j in range(w):
            # Find the nearest color in the reference palette
            distance, index = tree.query(image[i, j, 1:])
            color_diff = reference_palette[index, 1:] - target_palette[index, 1:]
            
            # Apply the color transfer
            for k in range(1, 3):
                result_image[i, j, k] = np.clip(image[i, j, k] + color_diff[k - 1], 0, 255)

    return result_image.astype(np.uint8)



def remap_colors(image, target_palette, reference_palette, target_ratios, reference_ratios):
    enhanced_image = apply_brightness_transfer(image, target_palette, reference_palette, target_ratios, reference_ratios)
    enhanced_image = apply_color_transfer(enhanced_image, target_palette, reference_palette)
    return enhanced_image


def main():
    root = tk.Tk()
    root.withdraw()

    input_image_path = filedialog.askopenfilename(title="Select Input Image")
    input_image = cv2.imread(input_image_path)
    input_image_lab = cv2.cvtColor(input_image, cv2.COLOR_BGR2Lab)
    input_palette = k_means_clustering(input_image_lab)
    input_color_ranges = determine_color_ranges(input_palette)
    input_ratios = calculate_color_ratios(input_image_lab, input_color_ranges)

    reference_image_path = filedialog.askopenfilename(title="Select Reference Image")
    reference_image = cv2.imread(reference_image_path)
    reference_image_lab = cv2.cvtColor(reference_image, cv2.COLOR_BGR2Lab)
    reference_palette = k_means_clustering(reference_image_lab)
    reference_color_ranges = determine_color_ranges(reference_palette)
    reference_ratios = calculate_color_ratios(reference_image_lab, reference_color_ranges)

    enhanced_image_lab = remap_colors(input_image_lab, input_palette, reference_palette, input_ratios, reference_ratios)
    enhanced_image = cv2.cvtColor(enhanced_image_lab,    cv2.COLOR_Lab2BGR)

    # Show the enhanced image on the screen
    cv2.imshow('Enhanced Image', enhanced_image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    # Ask the user if they want to save the enhanced image
    save_choice = messagebox.askyesno("Save Enhanced Image", "Do you want to save the enhanced image?")
    if save_choice:
        save_path = filedialog.asksaveasfilename(defaultextension=".jpg", title="Save Enhanced Image",
                                                 filetypes=[("JPEG files", "*.jpg")])
        cv2.imwrite(save_path, enhanced_image)


if __name__ == "__main__":
    main()

