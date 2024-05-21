#!/usr/bin/env python3

import pydicom
import sys
import os
import numpy as np
from PIL import Image
import json

def save_image(dicom_data, output_folder, index=0):
    # Normalize the pixel data to 0-255
    image = dicom_data
    image = np.uint8((np.clip(image, 0, np.max(image)) / np.max(image)) * 255)
    
    # Convert to PIL Image to save in JPEG format
    im = Image.fromarray(image)
    im.save(os.path.join(output_folder, f"image_{index}.jpeg"))


def read_dicom_file(filepath, output_folder="."):
    # Load the DICOM file
    dicom_data = pydicom.dcmread(filepath)

    # Print all the metadata (DICOM tags)
    print("Metadata in the DICOM file:")
    data = {}
    for tag in dicom_data.dir():
        value = getattr(dicom_data, tag, "")
        if value is not None and tag != "PixelData":
            print(f"{tag}: {value}")
            data[tag] = str(value)

    json.dump(data, open(f"{output_folder}/metadata.json", "w"))

    # Check if the file contains image data and display info
    if 'PixelData' in dicom_data:
        print("\nImage data found in the file:")
        print(f"Dimensions: {dicom_data.Rows} x {dicom_data.Columns}")
        frames = 1
        if 'NumberOfFrames' in dicom_data:
            print(f"Number of Frames: {dicom_data.NumberOfFrames}")
            frames = dicom_data.NumberOfFrames
        else:
            print("Number of Frames: 1")
        print(f"Bits Stored: {dicom_data.BitsStored}")
        for i in range(frames):
            save_image(dicom_data.pixel_array[i], output_folder, i)
    else:
        print("\nNo image data found in the file.")


def process_files(directory, output_folder="."):
    # List all files in the specified directory
    for filename in os.listdir(directory):
        # Full path of the file
        full_path = os.path.join(directory, filename)
        
        # Check if it's a file and does not start with '.'
        if os.path.isfile(full_path) and not filename.startswith('.'):
            print(f"Processing file: {full_path}")
            # Place your file processing code here
            read_dicom_file(full_path, output_folder)


if __name__ == "__main__":
    # get file path from ARGV[1]
    input_folder = sys.argv[1]
    output_folder = "."
    if len(sys.argv) > 2:
        output_folder = sys.argv[2]
    print(f"Input folder: {input_folder} Output folder: {output_folder}")
    process_files(input_folder, output_folder)
