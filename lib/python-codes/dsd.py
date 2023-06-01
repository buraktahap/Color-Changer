import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk

def open_image():
    file_path = filedialog.askopenfilename()
    return Image.open(file_path)

def save_image(image):
    file_path = filedialog.asksaveasfilename(defaultextension=".jpg")
    image.save(file_path)

def display_image(image, canvas):
    tk_image = ImageTk.PhotoImage(image)
    canvas.create_image(0, 0, anchor="nw", image=tk_image)
    canvas.image = tk_image  # keep a reference to the image

def transfer_colors():
    source_image = open_image()
    target_image = open_image()

    output_image = color_transfer(source_image, target_image)  # you need to adapt color_transfer to work with PIL Images

    display_image(output_image, output_canvas)
    save_image(output_image)

root = tk.Tk()

source_button = tk.Button(root, text="Transfer Colors", command=transfer_colors)
source_button.pack()

output_canvas = tk.Canvas(root, width=500, height=500)
output_canvas.pack()

root.mainloop()
