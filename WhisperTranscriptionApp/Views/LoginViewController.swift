import UIKit

class LoginViewController: UIViewController {
    
    // UI Elements
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let signInButton = UIButton(type: .system)
    private let signUpButton = UIButton(type: .system)
    private let appleSignInButton = ASAuthorizationAppleIDButton() // From earlier setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure text fields
        emailTextField.placeholder = "Email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.borderStyle = .roundedRect
        
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.borderStyle = .roundedRect
        
        // Configure buttons
        signInButton.setTitle("Sign In", for: .normal)
        signUpButton.setTitle("Sign Up", for: .normal)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        
        // Add subviews
        [emailTextField, passwordTextField, signInButton, signUpButton, appleSignInButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Layout constraints
        NSLayoutConstraint.activate([
            emailTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 15),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            
            signInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            signInButton.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            signInButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),
            signInButton.heightAnchor.constraint(equalToConstant: 44),
            
            signUpButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 10),
            signUpButton.leadingAnchor.constraint(equalTo: signInButton.leadingAnchor),
            signUpButton.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: 44),
            
            appleSignInButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 20),
            appleSignInButton.leadingAnchor.constraint(equalTo: signInButton.leadingAnchor),
            appleSignInButton.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    @objc private func signInTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            ErrorAlertManager.shared.showAlert(
                title: "Missing Information",
                message: "Please enter both email and password.",
                in: self
            )
            return
        }
        
        SupabaseManager.shared.client.auth.signIn(email: email, password: password) { result in
            switch result {
            case .success(let session):
                // Handle successful login
                self.presentMainInterface()
            case .failure(let error):
                ErrorAlertManager.shared.showAlert(
                    title: "Login Error",
                    message: error.localizedDescription,
                    in: self
                )
            }
        }
    }
    
    @objc private func signUpTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            ErrorAlertManager.shared.showAlert(
                title: "Missing Information",
                message: "Please enter both email and password.",
                in: self
            )
            return
        }
        
        SupabaseManager.shared.client.auth.signUp(email: email, password: password) { result in
            switch result {
            case .success(let session):
                // Handle successful sign-up
                self.presentMainInterface()
            case .failure(let error):
                ErrorAlertManager.shared.showAlert(
                    title: "Sign Up Error",
                    message: error.localizedDescription,
                    in: self
                )
            }
        }
    }
    
    private func presentMainInterface() {
        DispatchQueue.main.async {
            let transcriptionListVC = TranscriptionListViewController()
            let navController = UINavigationController(rootViewController: transcriptionListVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true)
        }
    }
} 