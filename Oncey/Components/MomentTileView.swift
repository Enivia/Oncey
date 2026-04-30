import SwiftUI

struct MomentTileView: View {
    let moment: Moment
    let monthDayText: String
    let albumNameText: String
    let onEditNote: (() -> Void)?
    let onShare: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        moment: Moment,
        monthDayText: String,
        albumNameText: String,
        onEditNote: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.moment = moment
        self.monthDayText = monthDayText
        self.albumNameText = albumNameText
        self.onEditNote = onEditNote
        self.onShare = onShare
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s3) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.s3) {
                    Text(monthDayText)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Spacer(minLength: AppTheme.Spacing.s4)

                    Text(albumNameText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                if !trimmedNote.isEmpty {
                    Text(trimmedNote)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppTheme.Spacing.s5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(AppTheme.Colors.surface)
                .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .contextMenu {
            if let onEditNote {
                Button(action: onEditNote) {
                    Label("Note", systemImage: "long.text.page.and.pencil")
                }
            }

            if let onShare {
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }

            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var trimmedNote: String {
        moment.note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var coverImage: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size
            let fittedImageSize = AlbumCardCoverLayout.fittedImageSize(
                for: resolvedCoverSourceSize,
                in: containerSize
            )

            ZStack {
                LocalPhotoView(path: resolvedPhotoPath)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .blur(radius: resolvedPhotoPath == nil ? 0 : 20)
                    .scaleEffect(resolvedPhotoPath == nil ? 1 : 1.06)
                    .clipped()

                LocalPhotoView(path: resolvedPhotoPath, contentMode: .fit)
                    .frame(width: fittedImageSize.width, height: fittedImageSize.height)
            }
            .frame(width: containerSize.width, height: containerSize.height)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4 / 3, contentMode: .fit)
    }

    private var resolvedPhotoPath: String? {
        moment.photo.isEmpty ? nil : moment.photo
    }

    private var resolvedCoverSourceSize: CGSize {
        guard let resolvedPhotoPath,
              let imageSize = ImageResourceService.imageSize(from: resolvedPhotoPath),
              imageSize.width > 0,
              imageSize.height > 0 else {
            return CGSize(width: 4, height: 3)
        }

        return imageSize
    }
}

#Preview {
    let album = Album(name: "Weekend Escape")
    let moment = Moment(
        album: album,
        photo: "",
        note: "Morning light over the lake and a quiet dock.",
        createdAt: .now.addingTimeInterval(-86_400)
    )

    MomentTileView(
        moment: moment,
        monthDayText: "Apr 29",
        albumNameText: album.name
    )
    .padding()
    .background(AppTheme.Colors.background)
}
