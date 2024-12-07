from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from keras.models import load_model
from keras.preprocessing import image
import numpy as np
from io import BytesIO
from PIL import Image
import cv2
from patchify import patchify

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests

# Load the VGG16 model from .h5 file
#model = load_model('crop_prediction_VGG16#3.h5')
model = load_model('model.keras', custom_objects={"dice_loss": lambda x, y: x, "dice_coef": lambda x, y: x})

cf = {
    "image_size": 256,
    "num_channels": 3,
    "patch_size": 16,
    "flat_patches_shape": (256, 48)  # Updated dynamically later
}
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

@app.route('/flood', methods=['POST'])
def flood_prediction():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    img_file = request.files['image']

    # Read the image file into memory
    img = Image.open(BytesIO(img_file.read()))
    img = img.convert("RGB")  # Ensure the image is in RGB mode

    # Preprocess the image for prediction
    img = img.resize((cf["image_size"], cf["image_size"]))
    img_array = np.array(img) / 255.0

    # Patchify the image for model input
    patch_shape = (cf["patch_size"], cf["patch_size"], cf["num_channels"])
    patches = patchify(img_array, patch_shape, cf["patch_size"])
    patches = np.reshape(patches, (-1, patch_shape[0] * patch_shape[1] * cf["num_channels"]))
    patches = patches.astype(np.float32)
    patches = np.expand_dims(patches, axis=0)

    # Predict the mask
    pred = model.predict(patches, verbose=0)[0]
    pred = np.reshape(pred, (cf["image_size"], cf["image_size"], 1))
    pred = (pred > 0.5).astype(np.uint8)  # Threshold prediction

    # Find edges of the flood region using Canny edge detection
    pred_edges = cv2.Canny(pred[:, :, 0] * 255, 100, 200)

    # Make edges thicker using dilation
    kernel = np.ones((3, 3), np.uint8)  # Define a kernel (3x3 for moderate thickness)
    thicker_edges = cv2.dilate(pred_edges, kernel, iterations=1)

    # Create a blank RGB image to draw the thicker edges
    outline_mask = np.zeros((cf["image_size"], cf["image_size"], 3), dtype=np.uint8)
    outline_mask[:, :, 2] = thicker_edges  # Set the thicker edges to blue

    # Overlay the outline onto the original image
    img_array = (img_array * 255).astype(np.uint8)  # Convert to uint8
    combined_image = cv2.addWeighted(img_array, 0.9, outline_mask, 0.3, 0)
    # pred = model.predict(patches, verbose=0)[0]
    # pred = np.reshape(pred, (cf["image_size"], cf["image_size"], 1))
    # pred = (pred > 0.5).astype(np.uint8)  # Threshold prediction

    # # Create a blue mask for flood regions
    # blue_mask = np.zeros((cf["image_size"], cf["image_size"], 3), dtype=np.uint8)
    # blue_mask[:, :, 2] = pred[:, :, 0] * 255  # Set blue channel to 255 for flood regions

    # # Overlay the blue mask onto the original image
    # img_array = (img_array * 255).astype(np.uint8)  # Convert to uint8
    # combined_image = img_array.copy()

    # # Apply the blue mask only to flood regions
    # mask_indices = pred[:, :, 0] == 1
    # combined_image[mask_indices] = (0.7 * img_array[mask_indices] + 0.3 * blue_mask[mask_indices]).astype(np.uint8)

    # Save the combined image to a BytesIO object
    output = BytesIO()
    combined_pil_image = Image.fromarray(combined_image)
    combined_pil_image.save(output, format="PNG")
    output.seek(0)
    # Save the image in memory and send it as a response
#     output = BytesIO()
#     pred_pil_image = Image.fromarray(pred_image)
#     pred_pil_image.save(output, format="PNG")
#     output.seek(0)

    # Return the image as a response to the Flutter app
    return Response(output.getvalue(), mimetype='image/png')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
