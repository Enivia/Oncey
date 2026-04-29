import CoreGraphics

struct MomentTimelinePageMetrics {
    let containerSize: CGSize

    var pageSize: CGSize {
        CGSize(
            width: containerSize.width,
            height: max(0, containerSize.height * AppTheme.Layout.timelinePageHeightRatio)
        )
    }

    var verticalInset: CGFloat {
        max(0, (containerSize.height - pageSize.height) / 2)
    }

    var horizontalPadding: CGFloat {
        AppTheme.Layout.timelinePageHorizontalPadding
    }

    var contentSpacing: CGFloat {
        AppTheme.Layout.timelinePageContentSpacing
    }

    var timestampHeight: CGFloat {
        AppTheme.Layout.timelineTimestampHeight
    }

    var noteHeight: CGFloat {
        AppTheme.Layout.timelineNoteHeight
    }

    var photoMaxSize: CGSize {
        CGSize(
            width: max(0, pageSize.width - horizontalPadding * 2),
            height: max(0, pageSize.height - timestampHeight - noteHeight - contentSpacing * 2)
        )
    }

    func fittedPhotoSize(for sourceSize: CGSize) -> CGSize {
        AppTheme.Layout.fittedSize(for: sourceSize, maxSize: photoMaxSize)
    }

    func contentColumnWidth(for sourceSize: CGSize) -> CGFloat {
        fittedPhotoSize(for: sourceSize).width
    }
}