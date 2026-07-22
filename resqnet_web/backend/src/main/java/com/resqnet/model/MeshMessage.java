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

    public MeshMessage(String messageId, String senderId, String receiverId, String content, Long timestamp, Integer ttl, Integer hops, String status) {
        this.messageId = messageId;
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.content = content;
        this.timestamp = timestamp;
        this.ttl = ttl;
        this.hops = hops;
        this.status = status;
    }

    public String getMessageId() { return messageId; }
    public void setMessageId(String messageId) { this.messageId = messageId; }

    public String getSenderId() { return senderId; }
    public void setSenderId(String senderId) { this.senderId = senderId; }

    public String getReceiverId() { return receiverId; }
    public void setReceiverId(String receiverId) { this.receiverId = receiverId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Long getTimestamp() { return timestamp; }
    public void setTimestamp(Long timestamp) { this.timestamp = timestamp; }

    public Integer getTtl() { return ttl; }
    public void setTtl(Integer ttl) { this.ttl = ttl; }

    public Integer getHops() { return hops; }
    public void setHops(Integer hops) { this.hops = hops; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}

