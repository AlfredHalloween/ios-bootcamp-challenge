//
//  ListViewController.swift
//  iOS Bootcamp Challenge
//
//  Created by Jorge Benavides on 26/09/21.
//

import UIKit
import SVProgressHUD

class ListViewController: UICollectionViewController {

    private var pokemons: [Pokemon] = []
    private var resultPokemons: [Pokemon] = []

    // TODO: Use UserDefaults to pre-load the latest search at start
    let userSearchDefaults = UserDefaults.standard
    let searchKey: String = "search"

    private var latestSearch: String? {
        return userSearchDefaults.object(forKey: searchKey) as? String
    }

    lazy private var searchController: SearchBar = {
        let searchController = SearchBar("Search a pokemon", delegate: self)
        searchController.text = latestSearch
        searchController.showsCancelButton = !searchController.isSearchBarEmpty
        return searchController
    }()

    private var isFirstLauch: Bool = true

    // TODO: Add a loading indicator when the app first launches and has no pokemons
    private var shouldShowLoader: Bool = true {
        didSet {
            shouldShowLoader ? SVProgressHUD.show() : SVProgressHUD.dismiss()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setup()
        setupUI()
    }

    // MARK: Setup

    private func setup() {
        title = "Pokédex"

        // Customize navigation bar.
        guard let navbar = self.navigationController?.navigationBar else { return }

        navbar.tintColor = .black
        navbar.titleTextAttributes = [.foregroundColor: UIColor.black]
        navbar.prefersLargeTitles = true

        // Set up the searchController parameters.
        navigationItem.searchController = searchController
        definesPresentationContext = true

        refresh()
    }

    private func setupUI() {

        // Set up the collection view.
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.indicatorStyle = .white

        // Set up the refresh control as part of the collection view when it's pulled to refresh.
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.sendSubviewToBack(refreshControl)
    }

    // MARK: - UISearchViewController

    private func filterContentForSearchText(_ searchText: String) {
        // filter with a simple contains searched text
        resultPokemons = pokemons
            .filter {
                searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
            }
            .sorted {
                $0.id < $1.id
            }

        collectionView.reloadData()
    }

    // TODO: Implement the SearchBar

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultPokemons.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokeCell.identifier, for: indexPath) as? PokeCell
        else { preconditionFailure("Failed to load collection view cell") }
        cell.pokemon = resultPokemons[indexPath.item]
        return cell
    }

    // MARK: - Navigation

    // TODO: Handle navigation to detail view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DetailViewController.segueIdentifier {
            if let destinationVC = segue.destination as? DetailViewController {
                if let cell = sender as? PokeCell {
                    destinationVC.pokemon = cell.pokemon
                }
            }
        }
    }

    // MARK: - UI Hooks

    @objc func refresh() {
        shouldShowLoader = true
        var pokemons: [Pokemon] = []

        // TODO: Wait for all requests to finish before updating the collection view
        PokeAPI.shared.get(url: "pokemon?limit=30", onCompletion: { (list: PokemonList?, _) in
            guard let list = list else { return }
            let group = DispatchGroup()
            list.results.forEach { result in
                group.enter()
                PokeAPI.shared.get(url: "/pokemon/\(result.id)/", onCompletion: { (pokemon: Pokemon?, _) in
                    guard let pokemon = pokemon else { return }
                    pokemons.append(pokemon)
                    self.pokemons = pokemons
                    group.leave()
                })
            }
            group.notify(queue: DispatchQueue.main) {
                self.didRefresh()
            }
        })
    }

    private func didRefresh() {
        shouldShowLoader = false

        guard
            let collectionView = collectionView,
            let refreshControl = collectionView.refreshControl
        else { return }

        refreshControl.endRefreshing()

        filterContentForSearchText(latestSearch ?? "")
    }
}

// TODO: Implement the SearchBar
extension ListViewController: SearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {}
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        userSearchDefaults.set(searchText, forKey: searchKey)
        filterContentForSearchText(searchText)
    }
    
    func updateSearchResults(for text: String) {}
}

