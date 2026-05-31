package com.resqnet.repository;

import com.resqnet.model.MeshMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<MeshMessage, String> {
    List<MeshMessage> findAllByOrderByTimestampAsc();
}
