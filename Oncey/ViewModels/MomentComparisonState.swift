import Foundation

struct MomentComparisonState {
    enum Side {
        case leading
        case trailing
    }

    private(set) var moments: [Moment]
    private(set) var leadingMomentID: UUID?
    private(set) var trailingMomentID: UUID?
    private(set) var activeSide: Side?
    private(set) var isPickerExpanded = false

    init(moments: [Moment], currentMomentID: UUID?) {
        let orderedMoments = Self.orderedMoments(moments)
        self.moments = orderedMoments

        let selection = Self.defaultSelection(in: orderedMoments, currentMomentID: currentMomentID)
        leadingMomentID = selection.leading
        trailingMomentID = selection.trailing
    }

    var isComparisonAvailable: Bool {
        leadingMoment != nil && trailingMoment != nil
    }

    var leadingMoment: Moment? {
        moment(for: leadingMomentID)
    }

    var trailingMoment: Moment? {
        moment(for: trailingMomentID)
    }

    var selectableMoments: [Moment] {
        switch activeSide {
        case .leading:
            return moments.filter { $0.id != trailingMomentID }
        case .trailing:
            return moments.filter { $0.id != leadingMomentID }
        case nil:
            return moments
        }
    }

    mutating func presentPicker(for side: Side) {
        if isPickerExpanded, activeSide == side {
            collapsePicker()
            return
        }

        activeSide = side
        isPickerExpanded = true
    }

    mutating func collapsePicker() {
        activeSide = nil
        isPickerExpanded = false
    }

    mutating func selectMoment(id: UUID) {
        guard isPickerExpanded,
              let activeSide,
              moments.contains(where: { $0.id == id }) else {
            return
        }

        switch activeSide {
        case .leading:
            guard id != trailingMomentID else {
                return
            }

            leadingMomentID = id
        case .trailing:
            guard id != leadingMomentID else {
                return
            }

            trailingMomentID = id
        }

        collapsePicker()
    }

    mutating func syncMoments(_ updatedMoments: [Moment], preferredCurrentMomentID: UUID? = nil) {
        let orderedMoments = Self.orderedMoments(updatedMoments)
        moments = orderedMoments

        guard orderedMoments.count > 1 else {
            leadingMomentID = orderedMoments.first?.id
            trailingMomentID = nil
            collapsePicker()
            return
        }

        let validMomentIDs = Set(orderedMoments.map(\ .id))
        let validLeadingMomentID = leadingMomentID.flatMap { validMomentIDs.contains($0) ? $0 : nil }
        let validTrailingMomentID = trailingMomentID.flatMap { validMomentIDs.contains($0) ? $0 : nil }

        if let validLeadingMomentID,
           let validTrailingMomentID,
           validLeadingMomentID != validTrailingMomentID {
            leadingMomentID = validLeadingMomentID
            trailingMomentID = validTrailingMomentID
            return
        }

        if let validLeadingMomentID {
            leadingMomentID = validLeadingMomentID
            trailingMomentID = Self.candidateID(
                excluding: validLeadingMomentID,
                preferredCurrentMomentID: preferredCurrentMomentID,
                in: orderedMoments
            )
            return
        }

        if let validTrailingMomentID {
            leadingMomentID = Self.candidateID(
                excluding: validTrailingMomentID,
                preferredCurrentMomentID: preferredCurrentMomentID,
                in: orderedMoments
            )
            trailingMomentID = validTrailingMomentID
            return
        }

        let selection = Self.defaultSelection(in: orderedMoments, currentMomentID: preferredCurrentMomentID)
        leadingMomentID = selection.leading
        trailingMomentID = selection.trailing
    }

    private func moment(for id: UUID?) -> Moment? {
        guard let id else {
            return nil
        }

        return moments.first { $0.id == id }
    }

    private static func defaultSelection(in moments: [Moment], currentMomentID: UUID?) -> (leading: UUID?, trailing: UUID?) {
        guard let oldestMoment = moments.last else {
            return (nil, nil)
        }

        guard moments.count > 1 else {
            return (oldestMoment.id, nil)
        }

        let currentMoment = moments.first { $0.id == currentMomentID } ?? moments.first

        guard let currentMoment else {
            return (moments.first?.id, oldestMoment.id)
        }

        if currentMoment.id == oldestMoment.id,
           let latestMoment = moments.first {
            return (latestMoment.id, oldestMoment.id)
        }

        return (currentMoment.id, oldestMoment.id)
    }

    private static func candidateID(
        excluding excludedMomentID: UUID,
        preferredCurrentMomentID: UUID?,
        in moments: [Moment]
    ) -> UUID? {
        if let preferredCurrentMomentID,
           preferredCurrentMomentID != excludedMomentID,
           moments.contains(where: { $0.id == preferredCurrentMomentID }) {
            return preferredCurrentMomentID
        }

        return moments.first { $0.id != excludedMomentID }?.id
    }

    private static func orderedMoments(_ moments: [Moment]) -> [Moment] {
        MomentsViewModel().orderedMoments(moments)
    }
}