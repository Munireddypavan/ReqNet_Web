package com.resqnet.repository;

import com.resqnet.model.MeshNode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NodeRepository extends JpaRepository<MeshNode, String> {
}
