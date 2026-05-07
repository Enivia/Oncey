import SwiftUI
import CoreGraphics

struct MomentGalleryTileView: View {
    let moment: Moment

    var body: some View {
        LocalPhotoView(path: moment.photo)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
    }
}

#Preview {
    let album = Album(name: "Gallery")
    let moment = Moment(album: album, photo: "", createdAt: .now)

    MomentGalleryTileView(moment: moment)
        .frame(width: 120, height: 120)
        .padding()
        .background(AppTheme.Colors.background)
}
