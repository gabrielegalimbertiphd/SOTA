
# SOTA
State-of-the-art navigation system used for navigation test with blind people.

## Running the code:
1. Download the code
2. Open the file "esameMOBIDEV.xcodeproj" with XCode
3. Change the spatial representation in the file "UNImapCortile7.json" and insert all the positions of the markers and turning points for each path.
4. Change the spatial representation in the file "data.json" and insert all the edges connecting nodes and the navigation area size of each edge.
5. Run the code
6.Frame the first marker in the path "UNImapCortile7.json" (image name: "PercorsoXInizio) and begin the navigation towards the destination. The code is configured to start from the first turning point.

## Specification of the spatial representation:
The four routes used for the experiments, along with the positions of the visual markers on these routes, are contained in the file "UNImapCortile7.json". This file includes the coordinates for the markers, turning points, walls, and the perimeters of the buildings in the environment.
- To define the perimeter, update the latitude and longitude coordinates of each object in the "walls" field in the file "UNImapCortile7.json".
- For the markers, detailed information about their characteristics and positions is contained in the "works" key in the file "UNImapCortile7.json". You can modify each marker's latitude and longitude coordinates, id, floorId, imageVersion, title (the marker's name), author, printed width and height, and rotation (the heading relative to the reference system).
- The "paths" key defines the turning points of each path through the "coordinate" key. Each turning point includes latitude and longitude values. The name of each path is specified by the "name" key.
- The edges are determined by the sequence of coordinates connecting the turning points.
The file "data.json" contains all the information of the navigation graph.
- The "linksOfPaths" field contains all the edges (connections) of your navigation graphs. Each path is defined by a set of links between two nodes, labeled "node_u" and "node_v", along with the size of the corresponding navigation area.
- The "links" field contains the edges of a single navigation graph (useful for initialization). Each edge connects two nodes, labeled "node_u" and "node_v", and includes the size of the associated navigation area.
- The restricted navigation area is not used in this architecture.

## Markers
The images used for print the markers are contained in the folder "esameMOBIDEV/Assets.xcassets".
