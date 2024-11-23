from flask import Flask, request, jsonify
from flask_cors import CORS
from keras.models import load_model
from keras.preprocessing import image
import numpy as np
from io import BytesIO
from PIL import Image

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests

# Load the VGG16 model from .h5 file
model = load_model('crop_prediction_VGG16#3.h5')

# List of class names (update this according to your model's output classes)
class_names = ['jute','maize','rice','sugarcane','wheat']

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    img_file = request.files['image']

    # Read the image file into memory (no need to save to disk)
    img = Image.open(BytesIO(img_file.read()))

    # Preprocess the image for prediction
    img = img.resize((224, 224))  # Resize image to the expected size
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)

    # Make prediction
    preds = model.predict(img_array)
    print(preds)

    # Find the index of the class with the highest probability
    predicted_class_index = np.argmax(preds)
    predicted_class = class_names[predicted_class_index]

    # Return the predicted class
    return jsonify(predicted_class)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
