import SwiftUI

extension MainView {

    func presentAlert(
        title: String,
        message: String
    ) {

        alertState.title = title
        alertState.message = message
        alertState.isPresented = true
    }

    func presentSaveFeedback(
        title: String,
        message: String
    ) {

        saveFeedbackState.title = title
        saveFeedbackState.message = message
        saveFeedbackState.isPresented = true
    }
}

#Preview {

    MainView()
        .environmentObject(
            BatchQueueStore()
        )
}
