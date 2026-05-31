package com.resqnet.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "nodes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MeshNode {
    @Id
    private String id;
    private String name;
    private Long lastSeen;
    private Double lat;
    private Double lng;
}
