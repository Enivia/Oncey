import SwiftUI

struct MomentCard1: View {
    let moment: Moment
    let renderMode: MomentCardRenderMode

    private var metrics: StyledCard1Metrics {
        switch renderMode {
        case .full:
            .full
        case .thumbnail:
            .thumbnail
        }
    }

    private var locationText: String? {
        moment.location.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var noteText: String? {
        moment.note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var createdAtText: String {
        AppDateFormatters.momentTimestamp.string(from: moment.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            ZStack(alignment: .bottomLeading) {
                LocalPhotoView(path: moment.photo)
                    .aspectRatio(4 / 5, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: metrics.photoHeight)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(renderMode == .full ? 0.42 : 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: metrics.metaSpacing) {
                    if let locationText {
                        Label {
                            Text(locationText)
                                .lineLimit(renderMode == .thumbnail ? 1 : 2)
                                .truncationMode(.tail)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                        .font(metrics.locationFont)
                        .foregroundStyle(.white)
                        .padding(.horizontal, metrics.metaHorizontalPadding)
                        .padding(.vertical, metrics.metaVerticalPadding)
                        .background(.white.opacity(renderMode == .full ? 0.16 : 0.14))
                        .clipShape(Capsule())
                    }

                    Text(createdAtText)
                        .font(metrics.dateFont)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                }
                .padding(metrics.photoOverlayPadding)
            }
            .clipShape(RoundedRectangle(cornerRadius: metrics.photoCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: metrics.contentSpacing) {
                if let noteText {
                    Text(noteText)
                        .font(metrics.noteFont)
                        .foregroundStyle(Color(red: 0.2, green: 0.18, blue: 0.16))
                        .lineLimit(renderMode == .thumbnail ? 1 : nil)
                        .fixedSize(horizontal: false, vertical: renderMode == .full)
                }

                HStack(alignment: .center) {
                    Text("Oncey")
                        .font(metrics.brandFont)
                        .foregroundStyle(Color(red: 0.36, green: 0.31, blue: 0.27))

                    Spacer(minLength: 12)

                    Text(renderMode == .full ? "Captured Memory" : "Preview")
                        .font(metrics.captionFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.98, blue: 0.96),
                    Color(red: 0.95, green: 0.92, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: metrics.cardCornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct StyledCard1Metrics {
    let cardPadding: CGFloat
    let cardCornerRadius: CGFloat
    let photoCornerRadius: CGFloat
    let photoHeight: CGFloat
    let sectionSpacing: CGFloat
    let metaSpacing: CGFloat
    let contentSpacing: CGFloat
    let photoOverlayPadding: CGFloat
    let metaHorizontalPadding: CGFloat
    let metaVerticalPadding: CGFloat
    let locationFont: Font
    let dateFont: Font
    let noteFont: Font
    let brandFont: Font
    let captionFont: Font

    static let full = StyledCard1Metrics(
        cardPadding: 20,
        cardCornerRadius: 32,
        photoCornerRadius: 26,
        photoHeight: 360,
        sectionSpacing: 20,
        metaSpacing: 10,
        contentSpacing: 16,
        photoOverlayPadding: 20,
        metaHorizontalPadding: 14,
        metaVerticalPadding: 8,
        locationFont: .subheadline.weight(.semibold),
        dateFont: .subheadline,
        noteFont: .body,
        brandFont: .headline.weight(.semibold),
        captionFont: .caption.weight(.medium)
    )

    static let thumbnail = StyledCard1Metrics(
        cardPadding: 12,
        cardCornerRadius: 22,
        photoCornerRadius: 18,
        photoHeight: 148,
        sectionSpacing: 12,
        metaSpacing: 6,
        contentSpacing: 10,
        photoOverlayPadding: 12,
        metaHorizontalPadding: 10,
        metaVerticalPadding: 6,
        locationFont: .caption.weight(.semibold),
        dateFont: .caption2,
        noteFont: .caption,
        brandFont: .caption.weight(.semibold),
        captionFont: .caption2.weight(.medium)
    )
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
