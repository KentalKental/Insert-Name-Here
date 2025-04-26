import Util "../Util";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Option "mo:base/Option";

actor {
    let Service = Util.Service;
    let ServiceTier = Util.ServiceTier;
    let ServiceUpdate = Util.ServiceUpdateFormData;

    stable var services = HashMap.HashMap<Text, Service>(10, Text.equal, Text.hash);

    public shared func createService(freelancerId: Text, serviceData: Util.UnregisteredServiceFormData): async Result.Result<Service, Text> {
        if (serviceData.tiers.size() == 0) {
            return #err("At least one tier is required");
        };

        let now = Time.now();
        let newService = {
            id = Util.generateUUID();
            freelancerId = freelancerId;
            title = serviceData.title;
            description = serviceData.description;
            category = serviceData.category;
            subcategory = serviceData.subcategory;
            startingPrice = serviceData.tiers[0].price;
            currency = serviceData.currency;
            deliveryTimeMin = Array.min(Array.map(serviceData.tiers, func(tier) { tier.deliveryDays }));
            status = serviceData.status;
            tags = serviceData.tags;
            attachments = serviceData.attachments;
            tiers = serviceData.tiers;
            contractType = serviceData.contractType;
            paymentMethod = serviceData.paymentMethod;
            createdAt = now;
            updatedAt = now;
            averageRating = null;
            totalReviews = 0;
        };

        services.put(newService.id, newService);
        return #ok(newService);
    };

    public shared func updateService(serviceId: Text, updatedServiceData: Util.ServiceUpdateFormData): async Result.Result<Service, Text> {
        let service = services.get(serviceId);
        switch (service) {
            case (?serviceExists) {
                let updatedService = {
                    id = serviceExists.id;
                    freelancerId = serviceExists.freelancerId;
                    createdAt = serviceExists.createdAt;
                    updatedAt = Time.now();
                    title = updatedServiceData.title;
                    description = Option.get(updatedServiceData.description, serviceExists.description);
                    category = Option.get(updatedServiceData.category, serviceExists.category);
                    subcategory = Option.get(updatedServiceData.subcategory, serviceExists.subcategory);
                    startingPrice = Option.get(updatedServiceData.startingPrice, serviceExists.startingPrice);
                    currency = Option.get(updatedServiceData.currency, serviceExists.currency);
                    deliveryTimeMin = Option.get(updatedServiceData.deliveryTimeMin, serviceExists.deliveryTimeMin);
                    status = Option.get(updatedServiceData.status, serviceExists.status);
                    tags = Option.get(updatedServiceData.tags, serviceExists.tags);
                    attachments = Option.get(updatedServiceData.attachments, serviceExists.attachments);
                    tiers = Option.get(updatedServiceData.tiers, serviceExists.tiers);
                    contractType = Option.get(updatedServiceData.contractType, serviceExists.contractType);
                    paymentMethod = Option.get(updatedServiceData.paymentMethod, serviceExists.paymentMethod);
                    averageRating = serviceExists.averageRating;
                    totalReviews = serviceExists.totalReviews;
                };

                services.put(serviceId, updatedService);
                return #ok(updatedService);
            };
            case (null) {
                return #err("Service not found");
            };
        };
    };

    public shared func addPackage(serviceId: Text, packageData: ServiceTier): async Result.Result<Service, Text> {
        let now = Time.now();
        let service = services.get(serviceId);
        switch (service) {
            case (?existingService) {
                let newPackage = {
                    id = Util.generateUUID();
                    name = packageData.name;
                    description = packageData.description;
                    price = packageData.price;
                    deliveryDays = packageData.deliveryDays;
                    revisions = packageData.revisions;
                    features = packageData.features;
                };

                let updatedTiers = Array.append(existingService.tiers, [newPackage]);
                let updatedService = {
                    existingService with
                    tiers = updatedTiers;
                    updatedAt = now;
                };

                services.put(serviceId, updatedService);
                return #ok(updatedService);
            };
            case (null) {
                return #err("Service not found");
            };
        };
    };

    public shared func updatePackage(serviceId: Text, packageId: Text, updatedPackageData: Util.ServiceTierUpdateFormData): async Result.Result<Service, Text> {
        let service = services.get(serviceId);
        switch (service) {
            case (?existingService) {
                var packageFound = false;
                let updatedTiers = Array.map(existingService.tiers, func(tier: ServiceTier): ServiceTier {
                    if (tier.id == packageId) {
                        packageFound := true;
                        {
                            tier with
                            name = Option.get(updatedPackageData.name, tier.name);
                            description = Option.get(updatedPackageData.description, tier.description);
                            price = Option.get(updatedPackageData.price, tier.price);
                            deliveryDays = Option.get(updatedPackageData.deliveryDays, tier.deliveryDays);
                            revisions = Option.get(updatedPackageData.revisions, tier.revisions);
                            features = Option.get(updatedPackageData.features, tier.features);
                        }
                    } else {
                        tier
                    }
                });

                if (not packageFound) {
                    return #err("Package not found");
                };

                let updatedService = {
                    existingService with
                    tiers = updatedTiers;
                    updatedAt = Time.now();
                };

                services.put(serviceId, updatedService);
                return #ok(updatedService);
            };
            case (null) {
                return #err("Service not found");
            };
        };
    };

    public shared func removePackage(serviceId: Text, packageId: Text): async Result.Result<Service, Text> {
        let service = services.get(serviceId);
        switch (service) {
            case (?existingService) {
                let updatedTiers = Array.filter(existingService.tiers, func(tier: ServiceTier): Bool {
                    tier.id != packageId
                });

                if (updatedTiers.size() == existingService.tiers.size()) {
                    return #err("Package not found");
                };

                let updatedService = {
                    existingService with
                    tiers = updatedTiers;
                    updatedAt = Time.now();
                };

                services.put(serviceId, updatedService);
                return #ok(updatedService);
            };
            case (null) {
                return #err("Service not found");
            };
        };
    };

    public shared func deleteService(serviceId: Text): async Result.Result<Text, Text> {
        let service = services.get(serviceId);
        switch (service) {
            case (?serviceExists) {
                services.remove(serviceId);
                return #ok("Service deleted successfully");
            };
            case (null) {
                return #err("Service not found");
            };
        };
    };

    public shared func getServiceDetails(serviceId: Text): async Result.Result<Service, Text> {
        let service = services.get(serviceId);
        switch (service) {
            case (?serviceExists) {
                return #ok(serviceExists);
            };
            case (null) {
                return #err("Service not found");
            };
        };
    };

    public shared func listAllServices(): async [Service] {
        Iter.toArray(services.values());
    };

    public shared func listServicesByFreelancer(freelancerId: Principal): async [Service] {
        let allServices = await listAllServices();
        Array.filter(allServices, func(service: Service): Bool {
            service.freelancerId == freelancerId
        });
    };
}