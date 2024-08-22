# ZIG-RAYLIB-TEST

## Requiremnts

* Zig - 0.13.0


``
cd ./zig-raylib-test/ &&
zig build run
``

## Purpose
* The main purpose of this repo is to finally load VTK files via opengl
* I'm using raylib since it will abstract most of the complexities

## Objectives
- [x] Link with raylib
- [ ] Link with raylib using zig dependecies
- [x] Create basic window
  <img width="1680" alt="Screenshot 2024-08-08 at 22 49 41" src="https://github.com/user-attachments/assets/3197ee40-653c-41af-b93b-2862b74f3928">
- [x] Render basic 2D shapes with raylib (Circle, Triangle, Rectangle)
- [ ] Render basic 3D objects with raylib (Cube)
- [ ] Render complex 3D objects with raylib (Cone, Sphere, Donut)
- [ ] Develop basic camera controls (e.g., orbit, zoom, pan) for interacting with 3D models.
- [x] Implement functionality to load VTK files.
      <img width="849" alt="Screenshot 2024-08-21 at 22 12 35" src="https://github.com/user-attachments/assets/0416d161-3564-43dc-b6bd-26cff400e913">
      <img width="877" alt="Screenshot 2024-08-22 at 09 48 46" src="https://github.com/user-attachments/assets/7a9704cc-0043-4ec2-adfd-a4f7e277c6fe">
- [ ] Parse the VTK file format to extract vertex, edge, and polygon data.
- [ ] Write and integrate vertex and fragment shaders for rendering the VTK data.
- [ ] Implement basic lighting and shading.
- [ ] Use OpenGL to render the parsed VTK data in the raylib window.
- [ ] Create a simple UI for file loading, camera control, and rendering options.
- [ ] Use raylib's GUI components or integrate a minimal UI library.
- [ ] Optimize VTK loading and rendering performance.
- [ ] Implement frustum culling or level of detail (LOD) techniques.
