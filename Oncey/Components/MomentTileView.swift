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

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s2) {
                Text(albumNameText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(monthDayText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                if !trimmedNote.isEmpty {
                    Text(trimmedNote)
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppTheme.Spacing.s5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .fill(AppTheme.Colors.surface)
                .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.Shadow.softRadius, y: AppTheme.Shadow.softYOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
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
        LocalPhotoView(path: resolvedPhotoPath)
        .frame(maxWidth: .infinity)
        .aspectRatio(resolvedCoverAspectRatio, contentMode: .fit)
        .clipped()
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

    private var resolvedCoverAspectRatio: CGFloat {
        let sourceSize = resolvedCoverSourceSize
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            return 4 / 3
        }

        return sourceSize.width / sourceSize.height
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
