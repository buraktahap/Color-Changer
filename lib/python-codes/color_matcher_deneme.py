import os
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk
from color_matcher import ColorMatcher
from color_matcher.io_handler import load_img_file, save_img_file, FILE_EXTS
from color_matcher.normalizer import Normalizer

class ColorTransferApp:
    def __init__(self, window):
        self.window = window
        self.source_image_path = None
        self.target_image_path = None
        self.output_image_path = None

        # Button to select source image
        self.btn_select_source = tk.Button(window, text='Select Source Image', command=self.select_source_image)
        self.btn_select_source.pack()

        # Button to select target image
        self.btn_select_target = tk.Button(window, text='Select Target Image', command=self.select_target_image)
        self.btn_select_target.pack()

        # Button to apply color transfer
        self.btn_apply_transfer = tk.Button(window, text='Apply Color Transfer', command=self.apply_color_transfer)
        self.btn_apply_transfer.pack()

        # Label to show output image
        self.lbl_output_image = tk.Label(window)
        self.lbl_output_image.pack()

    def select_source_image(self):
        self.source_image_path = filedialog.askopenfilename()
        print(f'Selected source image: {self.source_image_path}')

    def select_target_image(self):
        self.target_image_path = filedialog.askopenfilename()
        print(f'Selected target image: {self.target_image_path}')

    def apply_color_transfer(self):
        if not self.source_image_path or not self.target_image_path:
            print('Please select both source and target images.')
            return

        img_src = load_img_file(self.source_image_path)
        img_ref = load_img_file(self.target_image_path)

        obj = ColorMatcher(src=img_src, ref=img_ref, method='mkl')
        img_res = obj.main()
        img_res = Normalizer(img_res).uint8_norm()

        self.output_image_path = os.path.join(os.path.dirname(self.target_image_path), 'output.png')
        save_img_file(img_res, self.output_image_path)

        print(f'Saved output image: {self.output_image_path}')
        self.show_output_image()

    def show_output_image(self):
        if not self.output_image_path:
            return

        image = Image.open(self.output_image_path)
        image = image.resize((250, 250), Image.ANTIALIAS)  # Resize image to fit the label
        photo = ImageTk.PhotoImage(image)

        self.lbl_output_image.configure(image=photo)
        self.lbl_output_image.image = photo  # Keep a reference to the image to prevent it from being garbage collected

if __name__ == '__main__':
    root = tk.Tk()
    app = ColorTransferApp(root)
    root.mainloop()
