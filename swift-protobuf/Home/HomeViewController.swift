//
//  HomeViewController.swift
//  swift-protobuf
//
//  Created by Car mudi on 25/02/23.
//

import UIKit
import Starscream

class HomeViewController: UIViewController {

    // MARK: - Define ui component

    private let commandField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.placeholder = "Enter a command"

        return textField
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        button.setTitle("Send", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 5

        return button
    }()

    private let responseLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = .darkGray

        return label
    }()

    // MARK: - Private properties

    private var isConnected: Bool = false

    private let socket: WebSocket

    // MARK: - Initialized

    init(socket: WebSocket) {
        self.socket = socket

        let nibName = String(describing: type(of: self))
        let bundle = Bundle(for: type(of: self))

        super.init(nibName: nibName, bundle: bundle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureWebSocket()
        configureUI()
    }

    // MARK: - Private methods

    private func configureUI() {
        // Add command field
        view.addSubview(commandField)
        NSLayoutConstraint.activate([
            commandField.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            commandField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commandField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            commandField.heightAnchor.constraint(equalToConstant: 80)
        ])

        // Add send button
        view.addSubview(sendButton)
        NSLayoutConstraint.activate([
            sendButton.topAnchor.constraint(equalTo: commandField.bottomAnchor, constant: 20),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Add response label
        view.addSubview(responseLabel)
        NSLayoutConstraint.activate([
            responseLabel.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 20),
            responseLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            responseLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            responseLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
    }

    private func configureWebSocket() {
        socket.delegate = self
        socket.connect()
    }

    private func sendWebSocketQueryBy(id: String = "", name: String = "", region: String = "") {
        let query = Pokemon_PokemonQuery.with {
            $0.id = id
            $0.name = name
            $0.region = region
        }

        if let binary = try? query.serializedData() {
            socket.write(data: binary)
        }
    }

    private func handleWebSocketEvent(with event: WebSocketEvent) {
        switch event {
        case .connected:
            isConnected = true

        case .disconnected:
            isConnected = false

        case .text(let text):
            responseLabel.text = text

        case .binary(let data):
            do {
                let message = try Pokemon_WebSocketMessage(serializedData: data)
                switch message.paylod {
                case .pokemonList(let list):
                    responseLabel.text = list.pokemon.description

                case .errorMessage(let errorMsg):
                    responseLabel.text = errorMsg.errorMessage

                case .none:
                    break
                }
            } catch {
                responseLabel.text = "Error deserializing protobuf message: \(error)"
            }

        case .cancelled:
            isConnected = false

        case .error(let error):
            isConnected = false
            responseLabel.text = String(describing: error?.localizedDescription)

        default:
            break
        }
    }

    // MARK: - Private objective-C methods

    @objc
    private func sendButtonTapped() {
        guard let command = commandField.text?.lowercased(), !command.isEmpty else {
            return
        }

        // Send command to server and display response in label
        sendCommand(command)
    }

}

extension HomeViewController {
    func sendCommand(_ command: String) {
        guard isConnected else {
            print("Error: WebSocket is not connected.")
            return
        }

        switch command {
        case "list":
            sendWebSocketQueryBy()

        case let getCommand where getCommand.hasPrefix("get"):
            let components = getCommand.components(separatedBy: " ")
            guard components.count == 3 else {
                print("Error: Invalid command format.")
                return
            }

            switch components[1] {
            case "id":
                sendWebSocketQueryBy(id: components[2])
            case "name":
                sendWebSocketQueryBy(name: components[2])
            case "region":
                sendWebSocketQueryBy(region: components[2])
            default:
                print("Error: Invalid command.")
                return
            }

        case "exit":
            socket.disconnect()

        default:
            print("Error: Invalid command.")
        }
    }

}

extension HomeViewController: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        handleWebSocketEvent(with: event)
    }
}
