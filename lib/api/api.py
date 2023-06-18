from flask import Flask, request, send_file
from flask import json
import numpy as np
import math
import cv2
import os
from werkzeug.datastructures import FileStorage
import io
from sklearn.cluster import KMeans
from sklearn.metrics import pairwise_distances_argmin_min
from sklearn.metrics import pairwise_distances
from sklearn.preprocessing import LabelEncoder
from scipy.spatial.distance import cdist

api = Flask(__name__)

@api.route('/convert_with_palette', methods=['POST'])
def color_transfer_with_palette():
    target_image: FileStorage = request.files['target_image']
    source_image: FileStorage = request.files['source_image']
      # Use json.loads to parse the JSON strings back into lists
    original_palette = json.loads(request.form['original_palette'])  # receive original color palette
    edited_palette = json.loads(request.form['edited_palette'])  # receive edited color palette
    print(original_palette)
    print(edited_palette)

    # Load images and apply color transformation
    s = cv2.cvtColor(cv2.imdecode(np.frombuffer(source_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)
    t = cv2.cvtColor(cv2.imdecode(np.frombuffer(target_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)

    # if s.all() == t.all() and original_palette == edited_palette:
    #     # Convert array into bytes, and then save in memory file
    #     t = cv2.cvtColor(s,cv2.COLOR_LAB2BGR)
    #     is_success, im_buf_arr = cv2.imencode(".jpg", t)
    #     byte_im = io.BytesIO(im_buf_arr.tobytes())
    #     print(is_success)
    #     # Return the image data in memory as file
    #     byte_im.seek(0)
    #     return send_file(byte_im, mimetype='image/jpeg')
    


   # Convert palettes to LAB color space
    original_palette = [cv2.cvtColor(np.uint8([[np.array(color)]]) , cv2.COLOR_RGB2LAB)[0][0] for color in original_palette] # type: ignore
    edited_palette = [cv2.cvtColor(np.uint8([[np.array(color)]]) , cv2.COLOR_RGB2LAB)[0][0] for color in edited_palette] # type: ignore


    # Cluster colors in the source image using original color palette
    
    s_lab = s.copy()
    s_lab_flattened = s_lab.reshape((-1, 3))

    # Cluster colors in the source image using original color palette
    kmeans = KMeans(n_clusters=len(original_palette), init=np.array(original_palette), n_init=1)
    kmeans.fit(s_lab_flattened)

    # Map the original palette to the edited palette
    palette_mapping = match_palette_to_edited_palette(kmeans.cluster_centers_, edited_palette)

    # Map the source image pixels to the edited palette
    labels = kmeans.predict(s_lab_flattened)
    s_mapped_flattened = np.array(edited_palette)[palette_mapping[labels]]

    # Reshape the mapped source image back to its original shape
    s_mapped = s_mapped_flattened.reshape(s_lab.shape)


    # Calculate mean and standard deviation of source and target images
    def get_mean_and_std(x):
        x_mean, x_std = cv2.meanStdDev(x)
        x_mean = np.hstack(np.around(x_mean,2))
        x_std = np.hstack(np.around(x_std,2))
        return x_mean, x_std
    
    s_mean, s_std = get_mean_and_std(s_mapped)
    t_mean, t_std = get_mean_and_std(t)

    # Apply color transfer
    height, width, channel = t.shape
    for i in range(0,height):
        for j in range(0,width):
            for k in range(0,channel):
                if not np.all(t[i, j, :] == 0):  # Skip if pixel is black
                    x = t[i,j,k]
                    x = ((x-t_mean[k])*(s_std[k]/t_std[k]))+s_mean[k]
                    if math.isnan(x):
                        continue  # Skip NaN values
                    x = round(x)
                    x = 0 if x<0 else x
                    x = 255 if x>255 else x
                    t[i,j,k] = x

    t = cv2.cvtColor(t,cv2.COLOR_LAB2BGR)
    
    # Convert array into bytes, and then save in memory file
    is_success, im_buf_arr = cv2.imencode(".jpg", t)
    print(is_success)
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
                if math.isnan(x):
                    continue  # Skip NaN values
                x = round(x)
                x = 0 if x<0 else x
                x = 255 if x>255 else x
                s[i,j,k] = x

    s = cv2.cvtColor(s,cv2.COLOR_LAB2BGR)

    # Convert array into bytes, and then save in memory file
    is_success, im_buf_arr = cv2.imencode(".jpg", s)
    byte_im = io.BytesIO(im_buf_arr.tobytes())
    print(is_success)

    # Return the image data in memory as file
    byte_im.seek(0)
    return send_file(byte_im, mimetype='image/jpeg')

def match_palette_to_edited_palette(original_palette, edited_palette):
    # Compute pairwise distances
    distances = cdist(original_palette, edited_palette, metric='minkowski')

    # Get the index of the closest color in the edited_palette for each color in the original_palette
    indices = np.argmin(distances, axis=1)

    return indices

if __name__ == '__main__':
    api.run(host='0.0.0.0', port=5003,debug=False)