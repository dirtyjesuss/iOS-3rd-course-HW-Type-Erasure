import Foundation

protocol CRUDable {
    associatedtype Element: Identifiable

    func create(_ element: Element, completion: @escaping (Result<Void, Error>) -> Void)
    func read(by id: Element.ID, completion: @escaping (Result<Element, Error>) -> Void)
    func update(with element: Element, completion: @escaping (Result<Element, Error>) -> Void)
    func delete(by id: Element.ID, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Type erasure implementation for CRUDable

private class _AnyCRUDableBox<Element: Identifiable>: CRUDable {
    func create(_ element: Element, completion: @escaping (Result<Void, Error>) -> Void) {
        fatalError("This method is abstract")
    }

    func read(by id: Element.ID, completion: @escaping (Result<Element, Error>) -> Void) {
        fatalError("This method is abstract")
    }

    func update(with element: Element, completion: @escaping (Result<Element, Error>) -> Void) {
        fatalError("This method is abstract")
    }

    func delete(by id: Element.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        fatalError("This method is abstract")
    }
}

private class _CRUDableBox<Base: CRUDable>: _AnyCRUDableBox<Base.Element> {
    private let _base: Base

    init(_ base: Base) {
        _base = base
    }

    override func create(_ element: Element, completion: @escaping (Result<Void, Error>) -> Void) {
        _base.create(element, completion: completion)
    }

    override func read(by id: Element.ID, completion: @escaping (Result<Element, Error>) -> Void) {
        _base.read(by: id, completion: completion)
    }

    override func update(with element: Element, completion: @escaping (Result<Element, Error>) -> Void) {
        _base.update(with: element, completion: completion)
    }

    override func delete(by id: Element.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        _base.delete(by: id, completion: completion)
    }
}

struct AnyCRUDable<Element: Identifiable>: CRUDable {
    private let _box: _AnyCRUDableBox<Element>

    init<CRUDableType: CRUDable>(_ crudable: CRUDableType) where CRUDableType.Element == Element {
        _box = _CRUDableBox(crudable)
    }

    func create(_ element: Element, completion: @escaping (Result<Void, Error>) -> Void) {
        _box.create(element, completion: completion)
    }

    func read(by id: Element.ID, completion: @escaping (Result<Element, Error>) -> Void) {
        _box.read(by: id, completion: completion)
    }

    func update(with element: Element, completion: @escaping (Result<Element, Error>) -> Void) {
        _box.update(with: element, completion: completion)
    }

    func delete(by id: Element.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        _box.delete(by: id, completion: completion)
    }
}

// MARK: - Use of AnyCRUDable

struct User: Identifiable {
    let id = UUID()
    let name: String
}

final class UserDataBase: CRUDable {
    private var container: [User] = []

    func create(_ element: User, completion: @escaping (Result<Void, Error>) -> Void) {
        container.append(element)
        completion(.success(()))
    }

    func read(by id: User.ID, completion: @escaping (Result<User, Error>) -> Void) {
        if let readElement = container.first(where: { $0.id == id}) {
            completion(.success(readElement))
        } else {
            completion(.failure(NSError()))
        }
    }

    func update(with element: User, completion: @escaping (Result<User, Error>) -> Void) {
        if let readElementIndex = container.firstIndex(where: { $0.id == element.id}) {
            container[readElementIndex] = element
            completion(.success(container[readElementIndex]))
        } else {
            completion(.failure(NSError()))
        }
    }

    func delete(by id: User.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        if let elementIndex = container.firstIndex(where: { $0.id == id}) {
            container.remove(at: elementIndex)
            completion(.success(()))
        } else {
            completion(.failure(NSError()))
        }
    }
}

final class UserService {
    var userDataBase: AnyCRUDable<User>!
}

let service = UserService()
service.userDataBase = AnyCRUDable(UserDataBase())
