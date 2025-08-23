package com.idiot.re_point.exchange.controller;

import com.idiot.re_point.exchange.dto.ExchangeRequest;
import com.idiot.re_point.exchange.dto.ExchangeResponse;
import com.idiot.re_point.exchange.service.ExchangeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/exchanges")
@RequiredArgsConstructor
public class ExchangeController {

    private final ExchangeService exchangeService;

    @PostMapping("/{uid}")
    public ResponseEntity<ExchangeResponse> exchange(
            @PathVariable String uid,
            @RequestBody ExchangeRequest req
    ) throws ExecutionException, InterruptedException {
        ExchangeResponse res = exchangeService.exchangeGiftcard(uid, req.getCardId());
        return ResponseEntity.ok(res);
    }
}