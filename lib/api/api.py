from flask import Flask, request, send_file
import numpy as np
import cv2
import os
from werkzeug.datastructures import FileStorage
import io

app = Flask(__name__)

@app.route('/convert', methods=['POST'])
def color_transfer():
    source_image: FileStorage = request.files['source_image']
    target_image: FileStorage = request.files['target_image']

    # Load images and apply color transformation
    s = cv2.cvtColor(cv2.imdecode(np.fromstring(source_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)
    t = cv2.cvtColor(cv2.imdecode(np.fromstring(target_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)

    def get_mean_and_std(x):
        x_mean, x_std = cv2.meanStdDev(x)
        x_mean = np.hstack(np.around(x_mean,2))
        x_std = np.hstack(np.around(x_std,2))
        return x_mean, x_std

    s_mean, s_std = get_mean_and_std(s)
    t_mean, t_std = get_mean_and_std(t)

    height, width, channel = s.shape
    for i in range(0,height):
        for j in range(0,width):
            for k in range(0,channel):
                x = s[i,j,k]
                x = ((x-s_mean[k])*(t_std[k]/s_std[k]))+t_mean[k]
                x = round(x)
                x = 0 if x<0 else x
                x = 255 if x>255 else x
                s[i,j,k] = x

    s = cv2.cvtColor(s,cv2.COLOR_LAB2BGR)

    # Convert array into bytes, and then save in memory file
    is_success, im_buf_arr = cv2.imencode(".jpg", s)
    byte_im = io.BytesIO(im_buf_arr.tobytes())

    # Return the image data in memory as file
    byte_im.seek(0)
    return send_file(byte_im, mimetype='image/jpeg')

if __name__ == '__main__':
    app.run(debug=True)
