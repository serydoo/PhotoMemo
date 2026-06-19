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
}

#Preview {

    MainView()
        .environmentObject(
            BatchQueueStore()
        )
}
