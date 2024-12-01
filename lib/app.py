import os
import onnxruntime
import numpy as np
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from keras.models import load_model
from keras.preprocessing import image
from PIL import Image
from io import BytesIO
import gc  # Import garbage collector for memory management

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests

# Load the VGG16 model from .h5 file
model = load_model('crop_prediction_VGG16#3.h5')

# Load the ONNX model for SAR image colorization
onnx_model_path = "sar2rgb.onnx"
onnx_sess = onnxruntime.InferenceSession(onnx_model_path)

# List of class names for VGG16 model
class_names = ['jute', 'maize', 'rice', 'sugarcane', 'wheat']

@app.route('/predict1', methods=['POST'])
def predict_vgg16():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    img_file = request.files['image']

    # Clear any previous image and data before loading new one
    gc.collect()

    # Read the image file into memory (no need to save to disk)
    img = Image.open(BytesIO(img_file.read()))

    # Preprocess the image for VGG16 model
    img = img.resize((224, 224))  # Resize image to the expected size
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)

    # Make prediction
    preds = model.predict(img_array)

    # Find the index of the class with the highest probability
    predicted_class_index = np.argmax(preds)
    predicted_class = class_names[predicted_class_index]

    # Return the predicted class
    return jsonify(predicted_class)

@app.route('/predict2', methods=['POST'])
def predict_onnx():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    img_file = request.files['image']

    # Clear any previous image and data before loading new one
    gc.collect()

    # Read and preprocess the image for the ONNX model
    img = Image.open(BytesIO(img_file.read()))
    img = img.resize((256, 256))  # Adjust size as needed
    img = np.array(img).transpose(2, 0, 1)  # HWC to CHW
    img = img.astype(np.float32) / 255.0  # Normalize to [0, 1]
    img = (img - 0.5) / 0.5  # Normalize to [-1, 1]
    img = np.expand_dims(img, axis=0)  # Add batch dimension

    # Run the ONNX model
    inputs = {onnx_sess.get_inputs()[0].name: img}
    output = onnx_sess.run(None, inputs)

    # Post-process the output image
    output_image = output[0].squeeze().transpose(1, 2, 0)  # CHW to HWC
    output_image = (output_image + 1) / 2  # Normalize to [0, 1]
    output_image = (output_image * 255).astype(np.uint8)  # Denormalize to [0, 255]

    # Convert to Image and return as response
    output_image = Image.fromarray(output_image)
    img_byte_arr = BytesIO()
    output_image.save(img_byte_arr, format='PNG')
    img_byte_arr.seek(0)

    return send_file(img_byte_arr, mimetype='image/png')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
