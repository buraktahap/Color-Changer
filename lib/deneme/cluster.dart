// import 'dart:math';
// 
// class Point {
//   final double x;
//   final double y;
// 
//   Point(this.x, this.y);
// }
// 
// class Cluster {
//   List<Point> points;
//   Point centroid;
// 
//   Cluster(Point initialCentroid)
//       : centroid = initialCentroid,
//         points = [];
// 
//   void clearPoints() {
//     points.clear();
//   }
// 
//   void addPoint(Point point) {
//     points.add(point);
//   }
// 
//   void updateCentroid() {
//     double sumX = points.map((p) => p.x).reduce((a, b) => a + b);
//     double sumY = points.map((p) => p.y).reduce((a, b) => a + b);
//     centroid = Point(sumX / points.length, sumY / points.length);
//   }
// }
// 
// List<Cluster> performClustering(List<Point> data, int numClusters) {
//   // Initialize clusters with random centroids
//   List<Cluster> clusters = [];
//   List<Point> centroids = _getRandomPoints(data, numClusters);
//   for (int i = 0; i < numClusters; i++) {
//     clusters.add(Cluster(centroids[i]));
//   }
// 
//   bool centroidsChanged = true;
//   while (centroidsChanged) {
//     centroidsChanged = false;
// 
//     // Clear points from previous iteration
//     for (var cluster in clusters) {
//       cluster.clearPoints();
//     }
// 
//     // Assign points to the closest cluster
//     for (var point in data) {
//       Cluster closestCluster = _findClosestCluster(point, clusters);
//       closestCluster.addPoint(point);
//     }
// 
//     // Update centroids and check for convergence
//     for (var cluster in clusters) {
//       Point oldCentroid = cluster.centroid;
//       cluster.updateCentroid();
//       if (!_pointsEqual(oldCentroid, cluster.centroid)) {
//         centroidsChanged = true;
//       }
//     }
//   }
// 
//   return clusters;
// }
// 
// Cluster _findClosestCluster(Point point, List<Cluster> clusters) {
//   double minDistance = double.infinity;
//   Cluster closestCluster = clusters[0]; // Initialize with a default value
//   for (var cluster in clusters) {
//     double distance = _euclideanDistance(point, cluster.centroid);
//     if (distance < minDistance) {
//       minDistance = distance;
//       closestCluster = cluster;
//     }
//   }
//   return closestCluster;
// }
// 
// double _euclideanDistance(Point p1, Point p2) {
//   double dx = p1.x - p2.x;
//   double dy = p1.y - p2.y;
//   return sqrt(dx * dx + dy * dy);
// }
// 
// List<Point> _getRandomPoints(List<Point> data, int numPoints) {
//   var random = Random();
//   List<Point> randomPoints = [];
//   for (int i = 0; i < numPoints; i++) {
//     randomPoints.add(data[random.nextInt(data.length)]);
//   }
//   return randomPoints;
// }
// 
// bool _pointsEqual(Point p1, Point p2) {
//   return p1.x == p2.x && p1.y == p2.y;
// }
// 
// // Usage example
// void main() {
//   List<Point> data = [
//     Point(1.0, 2.0),
//     Point(3.0, 4.0),
//     Point(5.0, 6.0),
//     // ... add more data points
//   ];
// 
//   int numClusters = 3;
// 
//   List<Cluster> clusters = performClustering(data, numClusters);
// 
//   // Do something with the clusters
//   // ...
// }
