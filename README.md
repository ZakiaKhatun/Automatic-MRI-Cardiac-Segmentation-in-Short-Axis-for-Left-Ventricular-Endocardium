# Automatic MRI Cardiac Segmentation in Short Axis for Left Ventricular Endocardium
In this project, an automatic left ventricle (LV) segmentation algorithm is presented which is very important to assess cardiac functional parameters.

The main aim of this study was to develop a novel and robust algorithm which can improve the accuracy of automatic LV segmentation in short axis cardiac cine MR images. Our algorithm comprises four steps which are as follows:
- Motion quantification to determine an initial region of interest surrounding the heart, 
- Identification of potential 2D objects of interest using an intensity-based segmentation, 
- Assessment of contraction/expansion, circularity, and proximity to lung tissue to score all objects of interest in terms of their likelihood of constituting part of the LV, and
- Aggregation of the objects into connected groups and construction of the final LV blood pool volume and centroid.

Note: This project was the project of the first semester of my master's in the 'Sensors and digitization' course.
