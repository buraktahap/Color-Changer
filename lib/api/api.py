from flask import Flask, request, send_file
from flask import json
import numpy as np
import cv2
import os
from werkzeug.datastructures import FileStorage
import io
from sklearn.cluster import KMeans
from sklearn.metrics import pairwise_distances_argmin_min

api = Flask(__name__)

@api.route('/convert_with_palette', methods=['POST'])
def color_transfer_with_palette():
    target_image: FileStorage = request.files['target_image']
    source_image: FileStorage = request.files['source_image']
      # Use json.loads to parse the JSON strings back into lists
    original_palette = json.loads(request.form['original_palette'])  # receive original color palette
    edited_palette = json.loads(request.form['edited_palette'])  # receive edited color palette
    

    # Load images and apply color transformation
    s = cv2.cvtColor(cv2.imdecode(np.frombuffer(source_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)
    t = cv2.cvtColor(cv2.imdecode(np.frombuffer(target_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)

   # Convert palettes to LAB color space
    original_palette = [cv2.cvtColor(np.uint8([[np.array(color)]]) , cv2.COLOR_BGR2LAB)[0][0] for color in original_palette]
    edited_palette = [cv2.cvtColor(np.uint8([[np.array(color)]]) , cv2.COLOR_BGR2LAB)[0][0] for color in edited_palette]


    # Cluster colors in the source image using original color palette
    

    s_flattened = s.reshape((-1, 3))
    kmeans = KMeans(n_clusters=len(original_palette), init=np.array(original_palette))
    kmeans.fit(s_flattened)

    # Delete color clusters not present in edited_palette
    closest, _ = pairwise_distances_argmin_min(kmeans.cluster_centers_, np.array(edited_palette).reshape(-1, 3))
    valid_clusters = set(closest)

    mask = np.array([kmeans.labels_[i] in valid_clusters for i in range(len(s_flattened))])

    # Create a new all-black image
    s_new = np.zeros_like(s)

    # Get indices of valid clusters
    valid_indices = np.where(mask)

    # Copy pixels of valid clusters from the original image to the new image
    s_new.reshape((-1, 3))[valid_indices] = s_flattened[valid_indices]


    def get_mean_and_std(x):
        x_mean, x_std = cv2.meanStdDev(x)
        x_mean = np.hstack(np.around(x_mean,2))
        x_std = np.hstack(np.around(x_std,2))
        return x_mean, x_std

    s_mean, s_std = get_mean_and_std(s_new)
    t_mean, t_std = get_mean_and_std(t)

    height, width, channel = t.shape
    for i in range(0,height):
        for j in range(0,width):
            for k in range(0,channel):
                if not np.all(t[i, j, :] == 0):  # Skip if pixel is black
                    x = t[i,j,k]
                    x = ((x-t_mean[k])*(s_std[k]/t_std[k]))+s_mean[k]
                    x = round(x)
                    x = 0 if x<0 else x
                    x = 255 if x>255 else x
                    t[i,j,k] = x

    t = cv2.cvtColor(t,cv2.COLOR_LAB2BGR)

    # Convert array into bytes, and then save in memory file
    is_success, im_buf_arr = cv2.imencode(".jpg", t)
    byte_im = io.BytesIO(im_buf_arr.tobytes())

    # Return the image data in memory as file
    byte_im.seek(0)
    return send_file(byte_im, mimetype='image/jpeg')


@api.route('/convert', methods=['POST'])
def color_transfer():
    source_image: FileStorage = request.files['target_image']
    target_image: FileStorage = request.files['source_image']

    # Load images and apply color transformation
    s = cv2.cvtColor(cv2.imdecode(np.frombuffer(source_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)
    t = cv2.cvtColor(cv2.imdecode(np.frombuffer(target_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)


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
    api.run(host='0.0.0.0', port=5003,debug=False)
