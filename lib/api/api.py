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

def match_palette_to_edited_palette(original_palette, edited_palette):
    # Compute pairwise distances
    distances = cdist(original_palette, edited_palette, metric='minkowski')

    # Get the index of the closest color in the edited_palette for each color in the original_palette
    indices = np.argmin(distances, axis=1)

    return indices

@api.route('/convert_with_palette', methods=['POST'])
def color_transfer_with_palette():
    # ensure required parameters are present
    if not all(key in request.files for key in ['target_image', 'source_image']):
        return "Missing required file in request", 400
    if not all(key in request.form for key in ['original_palette', 'edited_palette']):
        return "Missing required form data in request", 400

    target_image: FileStorage = request.files['target_image']
    source_image: FileStorage = request.files['source_image']
    original_palette = json.loads(request.form['original_palette'])  # receive original color palette
    edited_palette = json.loads(request.form['edited_palette'])  # receive edited color palette

    # Load images and apply color transformation
    s = cv2.cvtColor(cv2.imdecode(np.frombuffer(source_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)
    t = cv2.cvtColor(cv2.imdecode(np.frombuffer(target_image.read(), np.uint8), cv2.IMREAD_COLOR), cv2.COLOR_BGR2LAB)

   # Convert palettes to LAB color space
    original_palette = [cv2.cvtColor(np.uint8([[np.array(color)]]) , cv2.COLOR_RGB2LAB)[0][0] for color in original_palette] # type: ignore
    edited_palette = [cv2.cvtColor(np.uint8([[np.array(color)]]) , cv2.COLOR_RGB2LAB)[0][0] for color in edited_palette] # type: ignore

    # Map the source image pixels to the closest color in the original palette
    s_lab = s.copy().reshape((-1, 3))
    labels = pairwise_distances_argmin_min(s_lab, original_palette, metric='minkowski')[0]

    # Map the original palette to the edited palette
    palette_mapping = match_palette_to_edited_palette(original_palette, edited_palette)

    # Map the source image pixels to the edited palette
    s_mapped_flattened = np.array(edited_palette)[palette_mapping[labels]]
    s_mapped = s_mapped_flattened.reshape(s.shape)

    # Calculate mean and standard deviation of source and target images
    s_mean, s_std = cv2.meanStdDev(s_mapped)
    s_mean, s_std = np.array(s_mean).flatten(), np.array(s_std).flatten()

    t_mean, t_std = cv2.meanStdDev(t)
    t_mean, t_std = np.array(t_mean).flatten(), np.array(t_std).flatten()

    # Apply color transfer
    t = ((t - t_mean) * (s_std / t_std)) + s_mean
    t = np.round(t).astype(np.float32)
    t = np.clip(t, 0, 255)

    # Convert back to 8-bit unsigned integer
    t = t.astype(np.uint8)

    t = cv2.cvtColor(t, cv2.COLOR_LAB2BGR)
    
    # Convert array into bytes, and then save in memory file
    is_success, im_buf_arr = cv2.imencode(".jpg", t)
    byte_im = io.BytesIO(im_buf_arr.tobytes())
    print(is_success)

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

    # Apply color transfer
    s = ((s - s_mean) * (t_std / s_std)) + t_mean
    s = np.round(s).astype(np.float32)
    s = np.clip(s, 0, 255)

    # Convert back to 8-bit unsigned integer
    s = s.astype(np.uint8)

    s = cv2.cvtColor(t, cv2.COLOR_LAB2BGR)
    # Convert array into bytes, and then save in memory file
    is_success, im_buf_arr = cv2.imencode(".jpg", s)
    byte_im = io.BytesIO(im_buf_arr.tobytes())
    print(is_success)

    # Return the image data in memory as file
    byte_im.seek(0)
    return send_file(byte_im, mimetype='image/jpeg')

@api.route('/convert_with_palette', methods=['POST'])
def color_transfer_with_palette_to_video():
    # ensure required parameters are present
    if not all(key in request.files for key in ['target_video', 'source_image']):
        return "Missing required file in request", 400
    if not all(key in request.form for key in ['original_palette', 'edited_palette']):
        return "Missing required form data in request", 400

    target_video: FileStorage = request.files['target_video']
    source_image: FileStorage = request.files['source_image']
    original_palette = json.loads(request.form['original_palette'])  # receive original color palette
    edited_palette = json.loads(request.form['edited_palette'])  # receive edited color palette

    # Load the source image
    source_image = cv2.imdecode(np.frombuffer(source_image.read(), np.uint8), cv2.IMREAD_COLOR)

    # Convert palettes to LAB color space
    original_palette_lab = [cv2.cvtColor(np.uint8([[np.array(color)]]), cv2.COLOR_RGB2LAB)[0][0] for color in original_palette] # type: ignore
    edited_palette_lab = [cv2.cvtColor(np.uint8([[np.array(color)]]), cv2.COLOR_RGB2LAB)[0][0] for color in edited_palette] # type: ignore

    # Open the target video file
    target_video_path = 'target_video.mp4'
    target_video.save(target_video_path)
    target_video = cv2.VideoCapture(target_video_path)

    # Get video properties
    frame_width = int(target_video.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(target_video.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = target_video.get(cv2.CAP_PROP_FPS)
    total_frames = int(target_video.get(cv2.CAP_PROP_FRAME_COUNT))

    # Create output video writer
    output_video_path = 'output_video.mp4'
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    output_video = cv2.VideoWriter(output_video_path, fourcc, fps, (frame_width, frame_height))

    # Process each frame of the target video
    for frame_idx in range(total_frames):
        ret, target_frame = target_video.read()
        if not ret:
            break

        # Convert target frame to LAB color space
        target_frame_lab = cv2.cvtColor(target_frame, cv2.COLOR_BGR2LAB)

        # Map the source image pixels to the closest color in the original palette
        source_frame_lab = source_image.reshape((-1, 3))
        labels = pairwise_distances_argmin_min(source_frame_lab, original_palette_lab, metric='minkowski')[0]

        # Map the original palette to the edited palette
        palette_mapping = match_palette_to_edited_palette(original_palette_lab, edited_palette_lab)

        # Map the source image pixels to the edited palette
        source_mapped_flattened = np.array(edited_palette_lab)[palette_mapping[labels]]
        source_mapped = source_mapped_flattened.reshape(source_image.shape)

        # Calculate mean and standard deviation of source and target frames
        source_mean, source_std = cv2.meanStdDev(source_mapped)
        source_mean, source_std = np.array(source_mean).flatten(), np.array(source_std).flatten()

        target_mean, target_std = cv2.meanStdDev(target_frame_lab)
        target_mean, target_std = np.array(target_mean).flatten(), np.array(target_std).flatten()

        # Apply color transfer
        target_frame_lab = ((target_frame_lab - target_mean) * (source_std / target_std)) + source_mean
        target_frame_lab = np.round(target_frame_lab).astype(np.float32)
        target_frame_lab = np.clip(target_frame_lab, 0, 255)

        # Convert back to BGR color space
        target_frame_bgr = cv2.cvtColor(target_frame_lab.astype(np.uint8), cv2.COLOR_LAB2BGR)

        # Write the modified frame to the output video
        output_video.write(target_frame_bgr)

    # Release resources
    target_video.release()
    output_video.release()

    # Send the resulting video file as a response
    return send_file(output_video_path, mimetype='video/mp4')

if __name__ == '__main__':
    api.run(host='0.0.0.0', port=5003,debug=False)