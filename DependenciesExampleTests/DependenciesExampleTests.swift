import Dependencies
import XCTest

// MARK: - Service A

struct ServiceA {
    
    let getSomeText: () -> String
    
}

extension ServiceA {

    static func live() -> Self {
        .init {
            "Live"
        }
    }

}

extension ServiceA: DependencyKey {

    static var liveValue: ServiceA {
        .live()
    }

}

extension DependencyValues {
    
    var a: ServiceA {
        get { self[ServiceA.self] }
        set { self[ServiceA.self] = newValue }
    }
    
}

// MARK: - Service B

struct ServiceB {

    let dependentOnA: ServiceA

}

extension ServiceB: DependencyKey {

    static var liveValue: ServiceB {
        .live()
    }

}

extension ServiceB {

    static func live() -> Self {
        @Dependency(\.a) var a

        return .init(dependentOnA: a)
    }
}

extension DependencyValues {
    
    var b: ServiceB {
        get { self[ServiceB.self] }
        set { self[ServiceB.self] = newValue }
    }
    
}

class SomeClassUsingDependency {
    
    @Dependency(\.b) var b
    
    func get() -> String {
        b.dependentOnA.getSomeText()
    }
    
}

// MARK: - Service C

struct ServiceC {

    var child: ServiceA

}

extension ServiceC: DependencyKey {

    static var liveValue: ServiceC {
        .live()
    }

    static var testValue: ServiceC {
        .init(child: .init(getSomeText: { "Default test value" }))
    }
    
}

extension ServiceC {

    static func live() -> Self {
        @Dependency(\.a) var a
        
        return .init(child: a)
    }
}

extension DependencyValues {
    
    var c: ServiceC {
        get { self[ServiceC.self] }
        set { self[ServiceC.self] = newValue }
    }
    
}

class SomeClassUsingServiceC {
    
    @Dependency(\.c) var c
    
    func get() -> String {
        c.child.getSomeText()
    }
    
}

// MARK: - Question A

final class QuestionA: XCTestCase {

    func test() {
        let sut = withDependencies {
            $0.a = .init {
                "Mock"
            }
        } operation: {
            withDependencies { inner in
                inner.b = .liveValue
            } operation: {
                SomeClassUsingDependency()
            }
        }

        XCTAssertEqual(sut.get(), "Mock")
    }
    
    func test_notWork() {
        let sut = withDependencies {
            $0.b = .init(dependentOnA: .init { "Mock" })
            // $0.a = .init { "Mock" } // Not work
        } operation: {
            SomeClassUsingDependency()
        }

        XCTAssertEqual(sut.get(), "Mock")
    }
    
}

// MARK: - Question B

class BaseTestCase: XCTestCase {
    
    override func invokeTest() {
        withDependencies {
            $0.c.child = .init {
                "Hello"
            }
        } operation: {
            super.invokeTest()
        }
    }
    
}

final class QuestionB: BaseTestCase {
    
    func test() {
        let sut = withDependencies {
            $0.c.child = .init {
                "World"
            }
        } operation: {
            SomeClassUsingServiceC()
        }

        // XCTAssertEqual(sut.get(), "World") // Failed
        XCTAssertEqual(sut.get(), "Hello")
    }
    
}
