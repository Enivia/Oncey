//
//  MomentTimelineRowView.swift
//  Oncey
//

import SwiftUI

struct MomentTimelineRowView: View {
    let moment: Moment
    let timestampText: String
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            TimelineRailView(isFirst: isFirst, isLast: isLast)

            VStack(alignment: .leading, spacing: 12) {
                Text(timestampText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LocalPhotoView(path: moment.photo)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
            }
        }
    }
}

private struct TimelineRailView: View {
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let nodeCenterY: CGFloat = 22

            ZStack(alignment: .top) {
                Path { path in
                    if !isFirst {
                        path.move(to: CGPoint(x: centerX, y: 0))
                        path.addLine(to: CGPoint(x: centerX, y: nodeCenterY))
                    }

                    if !isLast {
                        path.move(to: CGPoint(x: centerX, y: nodeCenterY))
                        path.addLine(to: CGPoint(x: centerX, y: geometry.size.height))
                    }
                }
                .stroke(Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .stroke(.background, lineWidth: 4)
                    }
                    .position(x: centerX, y: nodeCenterY)
            }
        }
        .frame(width: 28)
    }
}

#Preview {
    let album = Album(name: "Timeline Preview")
    let moment = Moment(album: album, photo: "", location: "Berlin, Germany")

    MomentTimelineRowView(moment: moment, timestampText: "Apr 18, 2026 at 7:05 PM", isFirst: true, isLast: false)
        .padding()
}