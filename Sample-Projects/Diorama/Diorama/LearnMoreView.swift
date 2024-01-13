/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view, used as an attachment, that gives information about a point of interest.
*/

import SwiftUI
import RealityKit
import RealityKitContent

public struct LearnMoreView: View {

    let name: String
    let description: String
    let imageNames: [String]
    let trail: Entity?
    
    let viewModel: ViewModel
    
    @State private var showingMoreInfo = false
    @Namespace private var animation
    
    private var imagesFrame: Double {
        showingMoreInfo ? 326 : 50
    }
    
    private var titleFont: Font {
        .system(size: 48, weight: .semibold)
    }
    
    private var descriptionFont: Font {
        .system(size: 36, weight: .regular)
    }
    
    public var body: some View {
        VStack {
            Spacer()
            ZStack(alignment: .center) {
                if !showingMoreInfo {
                    Text(name)
                        .matchedGeometryEffect(id: "Name", in: animation)
                        .font(titleFont)
                        .padding()
                }
                
                if showingMoreInfo {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(name)
                            .matchedGeometryEffect(id: "Name", in: animation)
                            .font(titleFont)
                        
                        Text(description)
                            .font(descriptionFont)
                        
                        if !imageNames.isEmpty {
                            Spacer()
                                .frame(height: 10)
                            
                            ImagesView(imageNames: imageNames)
                        }
                    }
                }
            }
            .frame(width: 408)
            .padding(24)
            .greenBackground()
            .onTapGesture {
                withAnimation(.spring) {
                    showingMoreInfo.toggle()
                    
                    if var trailOpacity = trail?.components[ControlledOpacityComponent.self] {
                        trailOpacity.shouldShow = showingMoreInfo
                        trail?.components.set(trailOpacity)
                    }
                    
                    viewModel.updateRegionSpecificOpacity()
                }
            }
        }
    }
}

struct ImagesView: View {
    let imageNames: [String]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(imageNames, id: \.self) { imageName in
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 250, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }
}

#Preview {
    RealityView { content, attachments in
        if let entity = attachments.entity(for: "z") {
            content.add(entity)
        }
    } attachments: {
        LearnMoreView(name: "Phoenix Lake",
                      description: "Lake · Northern California",
                      imageNames: ["Landscape_2_Sunset"],
                      trail: nil,
                      viewModel: ViewModel())
        .tag("z")
    }
}
