component displayname="SessionManager" {
    
    variables.sessions = {};
    variables.lock = createObject("java", "java.util.concurrent.locks.ReentrantReadWriteLock").init();
    
    public void function createSession(required string sessionId) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();
        try {
            variables.sessions[arguments.sessionId] = {
                "id": arguments.sessionId,
                "created": now(),
                "lastActivity": now(),
                "capabilities": {}
            };
        } finally {
            writeLock.unlock();
        }
    }
    
    public struct function getSession(required string sessionId) {
        var readLock = variables.lock.readLock();
        readLock.lock();
        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                return duplicate(variables.sessions[arguments.sessionId]);
            }
            return {};
        } finally {
            readLock.unlock();
        }
    }
    
    public void function updateActivity(required string sessionId) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();
        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                variables.sessions[arguments.sessionId].lastActivity = now();
            }
        } finally {
            writeLock.unlock();
        }
    }
    
    public void function removeSession(required string sessionId) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();        try {
            structDelete(variables.sessions, arguments.sessionId);
        } finally {
            writeLock.unlock();
        }
    }
}