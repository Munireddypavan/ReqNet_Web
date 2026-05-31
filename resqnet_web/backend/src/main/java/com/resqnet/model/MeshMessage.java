package com.resqnet.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MeshMessage {
    @Id
    private String messageId;
    private String senderId;
    private String receiverId;
    private String content;
    private Long timestamp;
    private Integer ttl;
    private Integer hops;
    private String status;
}
