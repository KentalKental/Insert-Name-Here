import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

actor {
    type Order = {
        orderId: Text;
        clientId: Principal;
        freelancerId: Principal;
        serviceId: Text;
        packageId: Text;
        status: Text; // "Pending", "In Progress", "Completed", "Cancelled"
    };

    let orders = HashMap.HashMap<Text, Order>(0, Text.equal, Text.hash);

    public func createOrder(clientId: Principal, serviceId: Text, packageId: Text, freelancerId: Principal) : async Text {
        let orderId = serviceId # "-" # packageId # "-" # Principal.toText(clientId);
        let newOrder: Order = {
            orderId = orderId;
            clientId = clientId;
            freelancerId = freelancerId;
            serviceId = serviceId;
            packageId = packageId;
            status = "Pending";
        };
        orders.put(orderId, newOrder);
        return orderId;
    };

    public func updateOrderStatus(orderId: Text, status: Text) : async Bool {
        switch (orders.get(orderId)) {
            case (?order) {
                let updatedOrder = {
                    orderId = order.orderId;
                    clientId = order.clientId;
                    freelancerId = order.freelancerId;
                    serviceId = order.serviceId;
                    packageId = order.packageId;
                    status = status;
                };
                orders.put(orderId, updatedOrder);
                return true;
            };
            case null {
                return false;
            };
        };
    };

    public query func listOrdersForClient(clientId: Principal) : async [Order] {
        let allOrders = Iter.toArray(orders.vals());
        return Array.filter<Order>(allOrders, func(o: Order): Bool { o.clientId == clientId });
    };

    public query func listOrdersForFreelancer(freelancerId: Principal) : async [Order] {
        let allOrders = Iter.toArray(orders.vals());
        return Array.filter<Order>(allOrders, func(o: Order): Bool { o.freelancerId == freelancerId });
    };

    public query func getOrderDetails(orderId: Text) : async ?Order {
        return orders.get(orderId);
    };
}
