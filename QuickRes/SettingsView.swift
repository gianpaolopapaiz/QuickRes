//
//  SettingsView.swift
//  QuickRes
//
//  Created by Gianpaolo Papaiz on 08/01/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            // About section
            Section {
                HStack(spacing: 16) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("QuickRes")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // General settings section
            Section {
                Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                    .toggleStyle(.switch)
                
                Toggle("Show in Dock", isOn: $settingsManager.showInDock)
                    .toggleStyle(.switch)
            } header: {
                Text("General")
            }
            
            if let error = settingsManager.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 320)
        .onAppear {
            settingsManager.refresh()
        }
    }
}

#Preview {
    SettingsView()
}
