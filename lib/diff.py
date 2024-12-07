from PIL import Image, ImageChops, ImageStat
import numpy as np

# Load the uploaded images
image_path_1 = "D:/College/Projects/RemoteSensing/archive/train/train/bangladesh_20170314t115609/tiles/vh/bangladesh_20170314t115609_x-5_y-29_vh.png"
image_path_2 = "D:/College/Projects/RemoteSensing/archive/train/train/bangladesh_20170314t115609/tiles/vv/bangladesh_20170314t115609_x-5_y-29_vv.png"

image_1 = Image.open(image_path_1).convert('L')  # Convert to grayscale for comparison
image_2 = Image.open(image_path_2).convert('L')

# Compute the difference between the two images
difference = ImageChops.difference(image_1, image_2)

# Calculate summary statistics for the differences
stats = ImageStat.Stat(difference)
difference_array = np.array(difference)

# Identify the specific areas of difference
non_zero_diff_indices = np.argwhere(difference_array > 0)

# Collecting detailed results
results = {
    "difference_image": difference,
    "sum_of_differences": stats.sum,
    "mean_difference": stats.mean,
    "extrema_of_differences": stats.extrema,
    "num_differing_pixels": len(non_zero_diff_indices)
}

Image._show(results)