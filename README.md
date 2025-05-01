
# SOTA
State-of-the-art navigation system used for navigation test with blind people.

## Running the code:
1. Download the code
2. Open the file "esameMOBIDEV.xcodeproj" with XCode
3. Change the spatial representation in the file "UNImapCortile7.json" and insert all the positions of the markers and turning points for each path.
4. Run the code
5. Frame the first marker in the path "UNImapCortile7.json" (name of the image "PercorsoXInizio") and start the navigation towards the destination. The code is set to work from the first turning point.

## Specification of the spatial representation:
The four routes used for the experiments as well as the position of the visual markers used in these routes are contained in the file "UNImapCortile7.json". In this files are contained the coordinates for markers, turning point, and walls and perimeters of buildings in the environment.
- For the perimeter, change the coordinates latitude and longitude of each object of "walls".
- For the markers, there are details on characteristic and position contained in key "works". It is possible to change the coordinates latitude and longitude of each marker, the id, the floorid, the imageversion, title (name of the marker), author, width and height of the printed marker and the rotation (heading with respect to the reference system) of the marker.
- The key "paths" indicates the coordinates of turning points in each path (key "coordinate"). Each turning point has associated a latitude and longitude coordinate. The name of the each path is the key "name".
- The edges are defined by the sequence of coordinates.
- The navigation area are defined in the code ARViewController in the variable "linksOfPaths". For each edge connecting a "node_u" and "node_v", the navigation area size is defined by the "radiusOfNavigationArea".
- The restricted navigation area is not used in this architecture.

## Markers
The images used for print the markers are contained in the folder "esameMOBIDEV/Assets.xcassets".
