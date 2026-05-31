package com.resqnet.controller;

import com.resqnet.model.MeshMessage;
import com.resqnet.model.MeshNode;
import com.resqnet.repository.MessageRepository;
import com.resqnet.repository.NodeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class MeshController {

    @Autowired
    private NodeRepository nodeRepository;

    @Autowired
    private MessageRepository messageRepository;

    @GetMapping("/nodes")
    public List<MeshNode> getAllNodes() {
        return nodeRepository.findAll();
    }

    @PostMapping("/nodes")
    public MeshNode upsertNode(@RequestBody MeshNode node) {
        return nodeRepository.save(node);
    }

    @GetMapping("/messages")
    public List<MeshMessage> getAllMessages() {
        return messageRepository.findAllByOrderByTimestampAsc();
    }

    @PostMapping("/messages")
    public MeshMessage insertMessage(@RequestBody MeshMessage message) {
        return messageRepository.save(message);
    }

    @PostMapping("/messages/status")
    public ResponseEntity<?> updateMessageStatus(@RequestBody Map<String, String> payload) {
        String messageId = payload.get("messageId");
        String status = payload.get("status");
        
        if (messageId == null || status == null) {
            return ResponseEntity.badRequest().body("Missing messageId or status");
        }

        Optional<MeshMessage> msgOpt = messageRepository.findById(messageId);
        if (msgOpt.isPresent()) {
            MeshMessage message = msgOpt.get();
            message.setStatus(status);
            messageRepository.save(message);
            return ResponseEntity.ok(message);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
