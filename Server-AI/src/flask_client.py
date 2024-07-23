import requests
import time

# Specify the URL of your Flask server endpoint
server_url = 'http://Put the server IP:5000/process_image'

# Open the image file you want to upload
with open('test8.png', 'rb') as image_file:
    # Create a dictionary to hold the file data
    files = {'image': image_file}

    # Send a POST request with the image file and enable streaming
    response = requests.post(server_url, files=files, stream=True)

    # Check if the request was successful
    if response.status_code == 200:
        for chunk in response.iter_content(chunk_size=1024):
            if chunk:
                # Process each chunk of data as it arrives
                print(chunk.decode('utf-8'))
                time.sleep(1)  # Simulate processing time
    else:
        print(f"Error: {response.status_code}")

# Print the final server's response
print(response)
