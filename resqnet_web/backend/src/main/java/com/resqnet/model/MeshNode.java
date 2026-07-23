package com.resqnet.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "nodes")
public class MeshNode {
    @Id
    private String id;
    private String name;
    private Long lastSeen;
    private Double lat;
    private Double lng;

    // Required by JPA and Jackson for deserialization
    public MeshNode() {}

    // Used by MeshWebSocketHandler to create nodes from WS payloads
    public MeshNode(String id, String name, Long lastSeen, Double lat, Double lng) {
        this.id = id;
        this.name = name;
        this.lastSeen = lastSeen;
        this.lat = lat;
        this.lng = lng;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public Long getLastSeen() { return lastSeen; }
    public void setLastSeen(Long lastSeen) { this.lastSeen = lastSeen; }

    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }

    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }
}
