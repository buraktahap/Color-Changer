# Color Changer

In this project, I wanted to combine my two main passions: mobile application development and photography. The main goal of the project is to transfer colors between images. Simply upload two images from your device and press one of the generation options below.

There are two generation options for creating the new image with transferred colors: 'Generate' and 'Generate From Palette'.

* The 'Generate' method is strongly related to Reinhard's color transfer algorithm.
* The 'Generate From Palette' option allows the user to remove unwanted colors from the source image and only transfer the remaining colors.

The mobile application was made with Flutter and the color transfer algorithms were written in Python using Flask. The Python file is located in lib/api/api.py.

If you want to run the project, make sure you have installed the Flutter and Python packages. In order to run successfully, you need to run both the api.py and main.dart files. Don't forget to check your emulators internet connection. Have a great time!

<table>
	<tbody width="100%">
		<tr>
			<th>Main Screen</th>	
			<th>Upload From Camera</th>	
			<th>Upload From Gallery</th>
		</tr>
		<tr>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/46a53b78-ebbf-4ce5-8110-c3ca797f620c"></img>
			</td>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/b3e7cdbe-0cfb-4794-b91b-6af2aeaa8682"></img>
			</td>
			<td>
			<img src="https://github.com/buraktahap/color_changer/assets/56032031/84de561c-467e-4608-851d-2c58efeadcab"></img>
			</td>
		</tr>
  	</tbody>
</table>

<table>
	<tbody width="100%">
		<tr>
			<th>Edit Screen</th>	
			<th>Save to gallery</th>	
			<th>Share</th>
		</tr>
		<tr>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/30386c94-735c-4d30-8e52-c26e27e80b1a"></img>
			</td>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/7f6d79b5-8fab-4beb-8a63-b2d2b17a301c"></img>
			</td>
			<td>
			<img src="https://github.com/buraktahap/color_changer/assets/56032031/6f63977f-040c-48b6-aee3-7839ee2579d7"></img>
			</td>
		</tr>
  	</tbody>
</table>

## Generate option

<table>
	<tbody width="100%">
		<tr>
			<th>Upload Source Image</th>	
			<th>Upload Target Image</th>	
			<th>Generate</th>
		</tr>
		<tr>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/a3dfe398-f02a-4f84-85f7-08e2ca5c4837"></img>
			</td>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/6d38e7a2-3732-4960-8de4-e7933652d8b8"></img>
			</td>
			<td>
			<img src="https://github.com/buraktahap/color_changer/assets/56032031/fb30e63f-7548-4dee-a582-ada9f7f4470a"></img>
			</td>
		</tr>
  	</tbody>
</table>

## Generate From Palette option

<table>
	<tbody width="100%">
		<tr>
			<th>Upload Source Image</th>	
			<th>Remove Colors From Palette</th>	
			<th>Generate From Palette</th>
		</tr>
		<tr>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/46903377-4c6f-498a-95b6-1801323cd5e7"></img>
			</td>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/c329e088-2598-41da-80ff-56f5810e1b8b"></img>
			</td>
			<td>
			<img src="https://github.com/buraktahap/color_changer/assets/56032031/f6835d13-5a2b-4015-a714-5d49aa56c9c5"></img>
			</td>
		</tr>
  	</tbody>
</table>

## Colorize B&W images with reference image

<table>
	<tbody>
		<tr>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/aabb7066-51dd-44e0-9b8f-682b112f0161"></img>
			</td>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/9afd04cd-ec90-4d7d-bbcf-e830eefdcd64"></img>
			</td>
		</tr>
  	</tbody>
</table>

## Turn any image to B&W

<table>
	<tbody>
		<tr>
			<td>
				<img alt="image" src="https://github.com/buraktahap/color_changer/assets/56032031/8adfe7b9-9370-4e05-b71a-d492428ce3a9"></img>
			</td>
			<td>
				<img src="https://github.com/buraktahap/color_changer/assets/56032031/8a9001d9-537c-4e4b-b1e4-744a90d900ff"></img>
			</td>
		</tr>
  	</tbody>
</table>




