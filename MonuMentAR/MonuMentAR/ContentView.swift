//
//  ContentView.swift
//  MonuMentAR
//
//  Created by Gustavo Caldas de Souza on 2025-09-30.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var showARView = false
    @State private var showLandmarkList = false
    @State private var showGPSTest = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Title
                VStack(spacing: 10) {
                    Text("MonuMentAR")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Discover Montreal's Landmarks in AR")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Main Action Buttons
                VStack(spacing: 20) {
                    // Start AR Experience Button
                    Button(action: {
                        showARView = true
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2)
                            Text("Start AR Experience")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // View Landmarks List Button
                    Button(action: {
                        showLandmarkList = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                            Text("View All Landmarks")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    
                    // GPS Test Button
                    Button(action: {
                        showGPSTest = true
                    }) {
                        HStack {
                            Image(systemName: "location.magnifyingglass")
                                .font(.title2)
                            Text("Test GPS Detection")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.green, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Features List
                VStack(alignment: .leading, spacing: 15) {
                    Text("Features")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    FeatureRow(icon: "location.fill", text: "GPS-based monument detection")
                    FeatureRow(icon: "gyroscope", text: "Motion sensor orientation tracking")
                    FeatureRow(icon: "target", text: "5 major Montreal landmarks")
                    FeatureRow(icon: "mappin.and.ellipse", text: "AR geo-anchored overlays")
                    FeatureRow(icon: "bolt.fill", text: "Instant recognition (no ML required)")
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showARView) {
            ARCameraViewWithOverlay()
        }
        .sheet(isPresented: $showLandmarkList) {
            LandmarkListView()
        }
        .sheet(isPresented: $showGPSTest) {
            GPSTestView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct LandmarkListView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(MontrealLandmark.landmarks) { landmark in
                LandmarkRowView(landmark: landmark)
            }
            .navigationTitle("Montreal Landmarks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LandmarkRowView: View {
    let landmark: MontrealLandmark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(landmark.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(landmark.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Text(landmark.architecturalStyle)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Text(landmark.yearBuilt)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
