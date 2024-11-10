struct OnboardingSlide {
    let title: String
    let description: String
    let imageName: String
    var action: (() -> Void)?

    var view: UIView {
        let slideView = UIView()
        // ...
        getStartedButton.addTarget(nil, action: #selector(buttonTapped), for: .touchUpInside)
        // ...
        return slideView
    }

    @objc private func buttonTapped() {
        action?()
    }
} 