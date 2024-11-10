import UIKit

class OnboardingViewController: UIViewController {
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private var slides: [OnboardingSlide] = []
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSlides()
        setupUI()
    }
    
    // MARK: - Setup Methods
    private func setupSlides() {
        slides = [
            OnboardingSlide(title: "Welcome", description: "Transcribe your thoughts effortlessly.", imageName: "onboarding1"),
            OnboardingSlide(title: "Record", description: "Record audio seamlessly.", imageName: "onboarding2"),
            OnboardingSlide(title: "Transcribe", description: "Get accurate transcriptions in real-time.", imageName: "onboarding3"),
            OnboardingSlide(title: "Manage", description: "Save and manage your transcriptions.", imageName: "onboarding4", action: getStartedTapped)
        ]
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .systemBlue
        
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        
        setupConstraints()
        setupSlideViews()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupSlideViews() {
        for (index, slide) in slides.enumerated() {
            let slideView = slide.view
            slideView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(slideView)
            
            NSLayoutConstraint.activate([
                slideView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                slideView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                slideView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                slideView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * view.frame.width)
            ])
        }
        
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height)
    }
    
    @objc private func getStartedTapped() {
        // Dismiss onboarding and present login screen
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = LoginViewController()
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
}

// MARK: - OnboardingSlide
struct OnboardingSlide {
    let title: String
    let description: String
    let imageName: String
    var action: (() -> Void)?
    
    var view: UIView {
        let slideView = UIView()
        
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        let getStartedButton = UIButton(type: .system)
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        getStartedButton.backgroundColor = .systemBlue
        getStartedButton.tintColor = .white
        getStartedButton.layer.cornerRadius = 8
        getStartedButton.clipsToBounds = true
        getStartedButton.addTarget(nil, action: #selector(buttonTapped), for: .touchUpInside)
        getStartedButton.isHidden = (title != "Manage")
        
        [imageView, titleLabel, descriptionLabel, getStartedButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            slideView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: slideView.safeAreaLayoutGuide.topAnchor, constant: 30),
            imageView.centerXAnchor.constraint(equalTo: slideView.centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: slideView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: slideView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: slideView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: slideView.trailingAnchor, constant: -20),
            
            getStartedButton.bottomAnchor.constraint(equalTo: slideView.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            getStartedButton.leadingAnchor.constraint(equalTo: slideView.leadingAnchor, constant: 50),
            getStartedButton.trailingAnchor.constraint(equalTo: slideView.trailingAnchor, constant: -50),
            getStartedButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return slideView
    }
    
    @objc private func buttonTapped() {
        action?()
    }
} 