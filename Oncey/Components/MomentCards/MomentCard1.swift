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
            LocalPhotoView(path: moment.photo, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .aspectRatio(photoAspectRatio, contentMode: .fit)

            if let noteText {
                Text(noteText)
                    .font(metrics.noteFont)
                    .lineLimit(renderMode == .thumbnail ? 2 : nil)
                    .fixedSize(horizontal: false, vertical: renderMode == .full)
            }

            if let locationText {
                Label {
                    Text(locationText)
                        .lineLimit(renderMode == .thumbnail ? 1 : nil)
                        .truncationMode(.tail)
                } icon: {
                    Image(systemName: "location.fill").foregroundStyle(AppTheme.Colors.accent).font(.system(size: 14))
                }
                .font(metrics.locationFont)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Text(createdAtText)
                .font(metrics.dateFont)
                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.8))
                .lineLimit(1)
        }
        .padding(metrics.padding)
        .border(AppTheme.Colors.border)
        .background(.white)
    }

    private var photoAspectRatio: CGFloat {
        guard let imageSize = ImageResourceService.imageSize(from: moment.photo), imageSize.width > 0, imageSize.height > 0 else {
            return 4 / 3
        }

        return imageSize.width / imageSize.height
    }
}

private struct StyledCard1Metrics {
    let sectionSpacing: CGFloat
    let locationFont: Font
    let dateFont: Font
    let noteFont: Font
    let padding: CGFloat

    static let full = StyledCard1Metrics(
        sectionSpacing: AppTheme.Spacing.s3,
        locationFont: .subheadline.weight(.semibold),
        dateFont: .subheadline,
        noteFont: .body,
        padding: AppTheme.Spacing.s6
    )

    static let thumbnail = StyledCard1Metrics(
        sectionSpacing: AppTheme.Spacing.s1,
        locationFont: .caption.weight(.semibold),
        dateFont: .caption2,
        noteFont: .caption,
        padding: AppTheme.Spacing.s2
    )
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview("Full") {
    let album = Album(name: "Weekend in Kyoto")
    let moment = Moment(
        album: album,
        photo: "",
        location: "Fushimi Inari, Kyoto",
        note: "Thousands of torii gates leading up the mountain — peaceful at sunrise.",
        createdAt: Date(timeIntervalSince1970: 1_714_233_600)
    )

    MomentCard1(moment: moment, renderMode: .full)
        .frame(maxWidth: 360)
        .padding()
        .background(AppTheme.Colors.background)
}

#Preview("Thumbnail") {
    let album = Album(name: "Weekend in Kyoto")
    let moment = Moment(
        album: album,
        photo: "",
        location: "Arashiyama, Kyoto",
        note: "Bamboo grove at dawn.",
        createdAt: Date(timeIntervalSince1970: 1_714_320_000)
    )

    MomentCard1(moment: moment, renderMode: .thumbnail)
        .frame(width: 120)
        .padding()
        .background(AppTheme.Colors.background)
}
