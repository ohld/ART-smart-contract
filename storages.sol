pragma solidity ^0.4.11;

contract queue
{
    struct Queue {
        bytes32[] data;
        uint front;
        uint back;
    }

    function _length(Queue storage q) constant internal returns (uint) {
        return q.back - q.front;
    }

    function _capacity(Queue storage q) constant internal returns (uint) {
        return q.data.length - 1;
    }

    function _push(Queue storage q, bytes32 data) internal {
        if ((q.back + 1) % q.data.length == q.front)
            q.data.length *= 2;
            // return; // throw;
        q.data[q.back] = data;
        q.back = (q.back + 1) % q.data.length;
    }

    function _pop(Queue storage q) internal returns (bytes32 r) {
        if (q.back == q.front)
            return; // throw;
        r = q.data[q.front];
        delete q.data[q.front];
        q.front = (q.front + 1) % q.data.length;
    }

    function _pop_back(Queue storage q) internal returns (bytes32 r) {
        if (q.back == q.front)
            return; // throw;
        r = q.data[q.back];
        delete q.data[q.back];
        q.back = (q.back - 1) % q.data.length;
    }

    function _if_in_queue(Queue storage q, bytes32 item) internal returns (bool) {
        for (uint i = 0; i < q.data.length; i++)
            if (q.data[i] == item) return true;
        return false;
    }

    function _delete(Queue storage q, bytes32 item) internal {
        for (uint i = 0; i < q.data.length; ++i) {
            if (q.data[i] == item) {
                for (uint j = i; j < q.data.length - 1; ++j)
                    q.data[j] = q.data[j + 1];
                q.data.length -= 1;
                return;
            }
        }
    }
}

contract Storages is queue {

    Queue public storages;
    mapping(bytes32 => Queue) public contents;

    function Storages() { storages.data.length = 2; }

    function add(bytes32 d) { _push(storages, d); }

    function get_storage() returns (bytes32 s) {
        s = _pop(storages);
        _push(storages, s);
    }

    function delete_storage(bytes32 s) {
        _delete(storages, s);
    }

    function add_content_to_storage(bytes32 s, bytes32 content_id) {
        if (contents[s].data.length == 0) {
            contents[s].data.length = 2;
            _push(contents[s], content_id);
        } else if (!_if_in_queue(contents[s], content_id))
            _push(contents[s], content_id);
    }
}
