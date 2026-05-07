import CoreGraphics

struct MomentTimelinePageMetrics {
    let containerSize: CGSize
    let heightReference: CGFloat

    init(containerSize: CGSize, heightReference: CGFloat? = nil) {
        self.containerSize = containerSize
        self.heightReference = heightReference ?? containerSize.height
    }

    var pageSize: CGSize {
        CGSize(
            width: containerSize.width,
            height: max(0, heightReference * AppTheme.Layout.momentsPageHeightRatio)
        )
    }

    var verticalInset: CGFloat {
        max(0, (containerSize.height - pageSize.height) / 2)
    }

    var horizontalPadding: CGFloat {
        AppTheme.Layout.momentsPageHorizontalPadding
    }

    var contentSpacing: CGFloat {
        AppTheme.Layout.momentsPageContentSpacing
    }

    var timestampHeight: CGFloat {
        AppTheme.Layout.momentsTimestampHeight
    }

    var noteHeight: CGFloat {
        AppTheme.Layout.momentsNoteHeight
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
