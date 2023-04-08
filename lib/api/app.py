import cv2
import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler
from flask import Flask, request, send_file
from flask_cors import CORS
from io import BytesIO
import base64

app = Flask(__name__)
CORS(app)

def find_clusters(image, k=5):
    pixels = image.reshape(-1, 3)
    kmeans = KMeans(n_clusters=k, n_init=10).fit(pixels)
    return kmeans

def apply_color_transfer(source, target, k=5):
    source = cv2.cvtColor(source, cv2.COLOR_BGR2LAB)
    target = cv2.cvtColor(target, cv2.COLOR_BGR2LAB)

    source_clusters = find_clusters(source, k)
    target_clusters = find_clusters(target, k)

    source_lab = source_clusters.cluster_centers_
    target_lab = target_clusters.cluster_centers_

    scaler = MinMaxScaler().fit(source_lab)
    source_lab_norm = scaler.transform(source_lab)
    target_lab_norm = scaler.transform(target_lab)

    distances = np.linalg.norm(source_lab_norm[:, np.newaxis] - target_lab_norm, axis=2)
    indices = np.argmin(distances, axis=1)

    result = np.copy(target)
    for i, index in enumerate(indices):
        source_mask = (source_clusters.labels_ == i).reshape(source.shape[:-1])
        target_mask = (target_clusters.labels_ == index).reshape(target.shape[:-1])

        source_pixels = source[source_mask]
        target_pixels = target[target_mask]

        min_len = min(len(source_pixels), len(target_pixels))
        if min_len == 0:
            continue

        target_pixels[:min_len] = target_pixels[:min_len] * (1 - source_lab_norm[i]) + source_pixels[:min_len] * source_lab_norm[i]
        result[target_mask] = target_pixels

    result = cv2.cvtColor(result, cv2.COLOR_LAB2BGR)

    return result


@app.route('/color_transfer', methods=['POST'])
def color_transfer():
    source_data = request.form['source_image']
    target_data = request.form['target_image']

    source_image = cv2.imdecode(np.frombuffer(base64.b64decode(source_data), dtype=np.uint8), cv2.IMREAD_COLOR)
    target_image = cv2.imdecode(np.frombuffer(base64.b64decode(target_data), dtype=np.uint8), cv2.IMREAD_COLOR)

    result = apply_color_transfer(source_image, target_image)

    _, buffer = cv2.imencode('.jpg', result)
    response = base64.b64encode(buffer)

    return response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
